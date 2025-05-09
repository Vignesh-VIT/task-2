output "nic_id" {
  description = "ID of the NIC"
  value       = azurerm_network_interface.nic.id
}

output "private_ip_address" {
  value = azurerm_network_interface.nic.private_ip_address
}
