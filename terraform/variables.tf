variable "environment" {
  description = "Deployment environment (dev, qa, prod)"
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for the resources"
  type        = string
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = list(string)
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = list(string)
}

variable "admin_username" {
  description = "Administrator username for VMs"
  type        = string
}

variable "public_key_path" {
  description = "The content of the SSH public key"
  type        = string
}

variable "public_vm_size" {
  description = "Size of the public virtual machine"
  type        = string
  default     = "Standard_B1s"
}

variable "private_vm_size" {
  description = "Size of the private virtual machine"
  type        = string
  default     = "Standard_B1s"
}
