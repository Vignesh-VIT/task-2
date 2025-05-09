# modules/keyvault/variables.tf
variable "name" {
  description = "Name of the Key Vault"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "vm_principal_id" {
  description = "Principal ID of the VM managed identity"
  type        = string
}

variable "db_password" {
  description = "Database password to store in Key Vault"
  type        = string
  sensitive   = true
}

variable "db_password_secret_name" {
  description = "Name of the database password secret"
  type        = string
  default     = "db-password"
}

variable "db_connection_string" {
  description = "Database connection string"
  type        = string
  sensitive   = true
}

variable "db_connection_secret_name" {
  description = "Name of the database connection string secret"
  type        = string
  default     = "db-connection-string"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}