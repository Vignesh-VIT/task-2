output "vm_id" {
  description = "ID of the Virtual Machine"
  value       = azurerm_linux_virtual_machine.vm.id
}

output "vm_name" {
  description = "Name of the Virtual Machine"
  value       = azurerm_linux_virtual_machine.vm.name
}

output "principal_id" {
  description = "Principal ID of the VM's managed identity"
  value       = azurerm_linux_virtual_machine.vm.identity[0].principal_id
}

output "private_ip_address" {
  description = "Private IP address of the VM"
  value       = azurerm_linux_virtual_machine.vm.private_ip_address
}