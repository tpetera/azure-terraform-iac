output "vm_public_ip" {
  description = "The public IP address of the Virtual Machine."
  value       = azurerm_public_ip.pip.ip_address
}

output "vm_id" {
  description = "The ID of the Virtual Machine."
  value       = azurerm_linux_virtual_machine.vm.id
}

output "vm_name" {
  description = "The name of the Virtual Machine."
  value       = azurerm_linux_virtual_machine.vm.name
}

output "vm_admin_username" {
  description = "The admin username for the Virtual Machine."
  value       = azurerm_linux_virtual_machine.vm.admin_username
}

output "vm_location" {
  description = "The Azure region where the VM is located."
  value       = azurerm_linux_virtual_machine.vm.location
}

output "network_interface_id" {
  description = "The ID of the primary network interface."
  value       = azurerm_linux_virtual_machine.vm.network_interface_ids[0] # Assumes one NIC
}

output "resource_group_name_used" {
  description = "The name of the resource group where the VM was deployed."
  value       = data.azurerm_resource_group.rg.name
}
