variable "resource_group_name" {
  type        = string
  description = "The name of the Azure Resource Group where resources will be created."
  default     = "rg-azure-iac-p1" # MAKE SURE THIS IS YOUR ACTUAL RG NAME
}

variable "location" {
  type        = string
  description = "The Azure region where resources will be created."
  default     = "West Europe" # MAKE SURE THIS IS YOUR ACTUAL RG LOCATION
}

variable "vm_count" {
  type        = number
  description = "The number of virtual machines to create."
  default     = 3
}

variable "vm_name_prefix" {
  type        = string
  description = "A prefix for the virtual machine names. VMs will be named <prefix>-<index>."
  default     = "tp-azure-vm"
}

variable "vm_size" {
  type        = string
  description = "The size of the virtual machine (e.g., Standard_B1s)."
  default     = "Standard_B1s"
}

variable "admin_username" {
  type        = string
  description = "The admin username for the virtual machine."
  default     = "azureadmuser"
}

variable "admin_ssh_public_key" {
  type        = string
  description = "The SSH public key data for authenticating to the VM. Content of your id_rsa.pub or similar."
  sensitive   = true
  # This will be provided via a GitHub secret.
}

variable "vm_image_publisher" {
  type        = string
  description = "The publisher of the VM image."
  default     = "Canonical"
}

variable "vm_image_offer" {
  type        = string
  description = "The offer of the VM image (e.g., ubuntu-24_04-lts for Ubuntu 24.04)."
  default     = "ubuntu-24_04-lts"
}

variable "vm_image_sku" {
  type        = string
  description = "The SKU of the VM image (e.g., server for Ubuntu 24.04 LTS Gen2)."
  default     = "server"
}

variable "vm_image_version" {
  type        = string
  description = "The version of the VM image. 'latest' is usually acceptable."
  default     = "latest"
}

variable "vnet_address_space" {
  type        = list(string)
  description = "The address space for the Virtual Network."
  default     = ["10.0.0.0/16"]
}

variable "vm_subnet_address_prefix" { # Renamed for clarity
  type        = list(string)
  description = "The address prefix for the VM Subnet."
  default     = ["10.0.1.0/24"]
}

variable "availability_set_name" {
  type        = string
  description = "Name for the Availability Set."
  default     = "vm-availability-set"
}

# --- New Variables for Application Gateway & WAF ---

variable "app_gateway_name" {
  type        = string
  description = "Name for the Application Gateway."
  default     = "tp-app-gw-p1"
}

variable "app_gateway_subnet_address_prefix" {
  type        = string # Note: Application Gateway subnet needs its own dedicated address space
  description = "The address prefix for the Application Gateway Subnet (e.g., 10.0.2.0/24)."
  default     = "10.0.2.0/24" # Ensure this doesn't overlap with vm_subnet_address_prefix
}

variable "app_gateway_public_ip_name" {
  type        = string
  description = "Name for the Public IP address of the Application Gateway."
  default     = "appgw-pip"
}

variable "waf_policy_name" {
  type        = string
  description = "Name for the Web Application Firewall (WAF) Policy."
  default     = "tpWAFPolicy"
}
