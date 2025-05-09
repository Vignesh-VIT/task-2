output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = azurerm_key_vault.main.id
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "db_password_secret_id" {
  description = "ID of the database password secret"
  value       = azurerm_key_vault_secret.db_password.id
}

output "db_connection_secret_id" {
  description = "ID of the database connection string secret"
  value       = azurerm_key_vault_secret.db_connection_string.id
}