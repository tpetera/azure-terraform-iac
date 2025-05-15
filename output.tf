output "application_gateway_public_ip" {
  description = "The public IP address of the Azure Application Gateway."
  value       = azurerm_public_ip.app_gateway_pip.ip_address # Corrected: was lb_pip, now app_gateway_pip
}

output "application_gateway_public_ip_fqdn" {
  description = "The FQDN of the Azure Application Gateway public IP (if available)."
  value       = azurerm_public_ip.app_gateway_pip.fqdn # Corrected: was lb_pip, now app_gateway_pip
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
  description = "Hint: VMs are behind an Application Gateway and do not have individual public IPs. To SSH into them, use Azure Bastion, a jump box within the VNet, or configure NAT rules (more advanced)."
  value       = "Connect to VMs using their private IPs from within the VNet (e.g., via a Bastion host). Example: ssh ${var.admin_username}@<A_VM_PRIVATE_IP> -i YOUR_PRIVATE_KEY_PATH"
}

output "application_gateway_name" {
  description = "The name of the Application Gateway."
  value       = azurerm_application_gateway.app_gateway.name
}

output "waf_policy_name_output" { # Added _output to avoid conflict with variable name if it existed
  description = "The name of the WAF Policy."
  value       = azurerm_web_application_firewall_policy.waf_policy.name
}
