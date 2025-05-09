variable "name" {
  description = "Name of the route table"
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

variable "subnet_id" {
  description = "ID of the subnet to associate with the route table"
  type        = string
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
}
