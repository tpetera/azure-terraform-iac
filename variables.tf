variable "resource_group_name" {
  type        = string
  description = "The name of the Azure Resource Group where resources will be created."
  default     = "rg-azure-iac-p1" # e.g., "azure-iac-rg" or "rg-azure-iac-p1" - MAKE SURE TO SET THIS
}

variable "location" {
  type        = string
  description = "The Azure region where resources will be created."
  default     = "West Europe" # region
}

variable "vm_count" {
  type        = number
  description = "The number of virtual machines to create."
  default     = 4
}

variable "vm_name_prefix" {
  type        = string
  description = "A prefix for the virtual machine names. VMs will be named <prefix>-<index>."
  default     = "tp-azure-vm" # VMs will be tp-azure-vm-0, tp-azure-vm-1, etc.
}

variable "vm_size" {
  type        = string
  description = "The size of the virtual machine (e.g., Standard_B1s)."
  default     = "Standard_B1s" # Typically eligible for Azure Free Tier (verify for your account)
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
  # This will be provided via a GitHub secret, not hardcoded here.
  # Ensure you have an SSH key pair. If not, you can generate one using 'ssh-keygen'.
}

variable "vm_image_publisher" {
  type        = string
  description = "The publisher of the VM image."
  default     = "Canonical"
}

variable "vm_image_offer" {
  type        = string
  description = "The offer of the VM image (e.g., ubuntu-24_04-lts for Ubuntu 24.04)."
  default     = "ubuntu-24_04-lts" # Updated for Ubuntu 24.04 LTS
}

variable "vm_image_sku" {
  type        = string
  description = "The SKU of the VM image (e.g., server for Ubuntu 24.04 LTS Gen2)."
  default     = "server" # Updated for Ubuntu 24.04 LTS (standard server Gen2)
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

variable "subnet_address_prefix" {
  type        = list(string)
  description = "The address prefix for the Subnet."
  default     = ["10.0.1.0/24"]
}

variable "availability_set_name" {
  type        = string
  description = "Name for the Availability Set."
  default     = "vm-availability-set"
}