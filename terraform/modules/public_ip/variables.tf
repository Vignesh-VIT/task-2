variable "name" {
  description = "Name of the public IP"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "allocation_method" {
  description = "IP allocation method: Static or Dynamic"
  type        = string
  default     = "Static"
}

variable "sku" {
  description = "SKU of the Public IP"
  type        = string
  default     = "Standard"
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
}