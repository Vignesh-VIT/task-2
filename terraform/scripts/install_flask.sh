#!/bin/bash

# Update system
apt-get update -y
apt-get upgrade -y

# Install Python and pip
apt-get install -y python3 python3-pip python3-venv nginx

# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Create application directory
mkdir -p /opt/flaskapp
cd /opt/flaskapp

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install required packages
pip install flask psycopg2-binary azure-keyvault-secrets azure-identity

# Create Flask application
cat > app.py << 'EOF'
from flask import Flask, jsonify
import psycopg2
from azure.keyvault.secrets import SecretClient
from azure.identity import DefaultAzureCredential
import os
import logging

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)

# Key Vault configuration
KEY_VAULT_URI = "${key_vault_uri}"

def get_secret_from_keyvault(secret_name):
    try:
        credential = DefaultAzureCredential()
        client = SecretClient(vault_url=KEY_VAULT_URI, credential=credential)
        secret = client.get_secret(secret_name)
        return secret.value
    except Exception as e:
        app.logger.error(f"Error retrieving secret {secret_name}: {e}")
        return None

def get_db_connection():
    try:
        connection_string = get_secret_from_keyvault("db-connection-string")
        if not connection_string:
            raise Exception("Could not retrieve database connection string")
        
        conn = psycopg2.connect(connection_string)
        return conn
    except Exception as e:
        app.logger.error(f"Database connection error: {e}")
        return None

@app.route('/')
def hello():
    return jsonify({
        "message": "Hello from Flask App!",
        "status": "running"
    })

@app.route('/health')
def health():
    try:
        conn = get_db_connection()
        if conn:
            cursor = conn.cursor()
            cursor.execute("SELECT version();")
            db_version = cursor.fetchone()
            conn.close()
            return jsonify({
                "status": "healthy",
                "database": "connected",
                "db_version": db_version[0] if db_version else "unknown"
            })
        else:
            return jsonify({
                "status": "unhealthy",
                "database": "disconnected"
            }), 500
    except Exception as e:
        return jsonify({
            "status": "unhealthy",
            "error": str(e)
        }), 500

@app.route('/data')
def get_data():
    try:
        conn = get_db_connection()
        if not conn:
            return jsonify({"error": "Database connection failed"}), 500
            
        cursor = conn.cursor()
        cursor.execute("SELECT id, name, created_at FROM sample_data ORDER BY created_at DESC LIMIT 10;")
        rows = cursor.fetchall()
        
        data = []
        for row in rows:
            data.append({
                "id": row[0],
                "name": row[1],
                "created_at": row[2].isoformat() if row[2] else None
            })
        
        conn.close()
        return jsonify({"data": data})
        
    except Exception as e:
        app.logger.error(f"Error fetching data: {e}")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
EOF

# Create systemd service
cat > /etc/systemd/system/flaskapp.service << 'EOF'
[Unit]
Description=Flask Application
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/flaskapp
Environment=PATH=/opt/flaskapp/venv/bin
ExecStart=/opt/flaskapp/venv/bin/python app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Configure Nginx
cat > /etc/nginx/sites-available/flaskapp << 'EOF'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Enable Nginx site
ln -sf /etc/nginx/sites-available/flaskapp /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Enable and start services
systemctl daemon-reload
systemctl enable flaskapp
systemctl enable nginx
systemctl start nginx

# Wait a moment for Key Vault access to be ready, then start Flask app
sleep 30
systemctl start flaskapp

echo "Flask application installation completed"