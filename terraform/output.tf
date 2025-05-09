output "vm_server1_private_ip" {
  description = "Private IP address of server1"
  value       = module.nic_server1.private_ip_address
}

output "vm_server1_public_ip" {
  value = module.public_ip.public_ip_address
}


output "vm_server2_private_ip" {
  description = "Private IP address of server2"
  value       = module.nic_server2.private_ip_address
}

output "vnet_id" {
  description = "ID of the created virtual network"
  value       = module.network.vnet_id
}
