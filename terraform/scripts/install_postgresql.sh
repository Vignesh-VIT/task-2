#!/bin/bash

# Update system
apt-get update -y
apt-get upgrade -y

# Install PostgreSQL
apt-get install -y postgresql postgresql-contrib

# Start and enable PostgreSQL
systemctl start postgresql
systemctl enable postgresql

# Configure PostgreSQL
sudo -u postgres psql << EOF
CREATE USER ${db_username} WITH PASSWORD '${db_password}';
CREATE DATABASE ${db_name} OWNER ${db_username};
GRANT ALL PRIVILEGES ON DATABASE ${db_name} TO ${db_username};
\q
EOF

# Configure PostgreSQL to accept connections
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/*/main/postgresql.conf

# Configure pg_hba.conf to allow connections from the public subnet
echo "host    all             all             10.0.1.0/24            md5" >> /etc/postgresql/*/main/pg_hba.conf

# Restart PostgreSQL to apply changes
systemctl restart postgresql

# Create sample data
sudo -u postgres psql -d ${db_name} << 'EOF'
CREATE TABLE sample_data (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO sample_data (name) VALUES 
    ('Sample Record 1'),
    ('Sample Record 2'),
    ('Sample Record 3'),
    ('Test Data Entry'),
    ('Flask App Data');
EOF

sudo -u postgres psql -d ${db_name} << EOF
GRANT SELECT ON sample_data TO ${db_username};
EOF


echo "PostgreSQL installation and configuration completed"