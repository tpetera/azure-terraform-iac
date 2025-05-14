output "load_balancer_public_ip" {
  description = "The public IP address of the Azure Load Balancer."
  value       = azurerm_public_ip.lb_pip.ip_address
}

output "load_balancer_public_ip_fqdn" {
  description = "The FQDN of the Azure Load Balancer public IP (if available)."
  value       = azurerm_public_ip.lb_pip.fqdn
}

output "vm_names" {
  description = "List of Virtual Machine names created."
  value       = [for vm in azurerm_linux_virtual_machine.vm : vm.name]
}

output "vm_private_ips" {
  description = "List of private IP addresses for the Virtual Machines (for internal access/Bastion/Jumpbox)."
  value       = [for nic in azurerm_network_interface.nic : nic.private_ip_address]
}

output "resource_group_name_used" {
  description = "The name of the resource group where resources were deployed."
  value       = data.azurerm_resource_group.rg.name
}

output "ssh_command_hint" {
  description = "Hint: VMs are behind a load balancer and do not have individual public IPs. To SSH into them, use Azure Bastion, a jump box within the VNet, or configure NAT rules on the Load Balancer (more advanced)."
  value       = "Connect to VMs using their private IPs from within the VNet (e.g., via a Bastion host). Example: ssh ${var.admin_username}@<A_VM_PRIVATE_IP> -i YOUR_PRIVATE_KEY_PATH"
}
