
output "linux_vm_private_ip" {
  description = "Private IP of Linux VM"
  value       = azurerm_network_interface.linux_nic.private_ip_address
}

output "windows_vm_private_ip" {
  description = "Private IP of Windows VM"
  value       = azurerm_network_interface.windows_nic.private_ip_address
}

output "external_lb_public_ip" {
  description = "Public IP address of external load balancer"
  value       = azurerm_public_ip.external_lb_ip.ip_address
}

output "internal_lb_private_ip" {
  description = "Private IP address of internal load balancer"
  value       = azurerm_lb.internal_lb.frontend_ip_configuration[0].private_ip_address
}
