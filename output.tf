output "vm_public_ips" {
  description = "List of public IP addresses for the Virtual Machines."
  value       = [for pip in azurerm_public_ip.pip : pip.ip_address]
}

output "vm_names" {
  description = "List of Virtual Machine names created."
  value       = [for vm in azurerm_linux_virtual_machine.vm : vm.name]
}

output "vm_private_ips" {
  description = "List of private IP addresses for the Virtual Machines."
  value       = [for nic in azurerm_network_interface.nic : nic.private_ip_address]
}

output "resource_group_name_used" {
  description = "The name of the resource group where resources were deployed."
  value       = data.azurerm_resource_group.rg.name
}

output "ssh_command_examples" {
  description = "Example SSH commands to connect to the VMs (replace YOUR_PRIVATE_KEY_PATH and use the appropriate public IP)."
  value = [
    for i in range(var.vm_count) :
    "ssh ${var.admin_username}@${azurerm_public_ip.pip[i].ip_address} -i YOUR_PRIVATE_KEY_PATH  # For VM: ${azurerm_linux_virtual_machine.vm[i].name}"
  ]
}
