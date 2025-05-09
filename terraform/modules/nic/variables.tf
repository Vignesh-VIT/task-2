variable "name" {
  description = "Name of the NIC"
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

variable "subnet_id" {
  description = "ID of the subnet"
  type        = string
}

variable "public_ip_id" {
  description = "ID of the Public IP (optional)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
}
