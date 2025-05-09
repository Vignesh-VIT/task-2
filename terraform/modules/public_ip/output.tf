output "public_ip_address" {
  description = "The IP address of the Public IP"
  value       = azurerm_public_ip.publicip.id
}
