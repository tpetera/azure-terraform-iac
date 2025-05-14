# Get a reference to the existing Resource Group
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# Create an Availability Set for the VMs
resource "azurerm_availability_set" "avset" {
  name                         = var.availability_set_name
  location                     = data.azurerm_resource_group.rg.location
  resource_group_name          = data.azurerm_resource_group.rg.name
  platform_fault_domain_count  = 2 # Number of fault domains
  platform_update_domain_count = 5 # Number of update domains
  tags = {
    environment = "dev"
    project     = "azure-iac-multi-vm-lb" # Updated project tag
  }
}

# Create a Virtual Network (VNet)
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.vm_name_prefix}-vnet"
  address_space       = var.vnet_address_space
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  tags = {
    environment = "dev"
    project     = "azure-iac-multi-vm-lb"
  }
}

# Create a Subnet within the VNet
resource "azurerm_subnet" "subnet" {
  name                 = "${var.vm_name_prefix}-subnet"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet_address_prefix
}

# Create a Network Security Group (NSG)
# This NSG will allow HTTP/HTTPS from anywhere (for the LB)
# and SSH (which would typically be from a Bastion/Jumpbox or specific IPs in a production setup)
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.vm_name_prefix}-nsg"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "Internet" # For SSH via Bastion, Jumpbox, or if direct access is configured later
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTP" # For the Load Balancer Health Probe and traffic
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet" # Or "AzureLoadBalancer" for health probe if restricting further
    destination_address_prefix = "*"
  }

   security_rule {
    name                       = "AllowHTTPS" # If you plan to use HTTPS later
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "dev"
    project     = "azure-iac-multi-vm-lb"
  }
}

# --- Azure Load Balancer Configuration ---

# Public IP for the Load Balancer
resource "azurerm_public_ip" "lb_pip" {
  name                = "${var.vm_name_prefix}-lb-pip" # Single Public IP for the LB
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard" # Standard SKU is required for Availability Sets/Zones with LB
  tags = {
    environment = "dev"
    project     = "azure-iac-multi-vm-lb"
  }
}

# Azure Load Balancer resource
resource "azurerm_lb" "lb" {
  name                = "${var.vm_name_prefix}-lb"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  sku                 = "Standard" # Must match the Public IP SKU

  frontend_ip_configuration {
    name                 = "${var.vm_name_prefix}-lb-frontend-ipconfig"
    public_ip_address_id = azurerm_public_ip.lb_pip.id
  }

  tags = {
    environment = "dev"
    project     = "azure-iac-multi-vm-lb"
  }
}

# Backend Address Pool for the Load Balancer
resource "azurerm_lb_backend_address_pool" "bap" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "${var.vm_name_prefix}-lb-backendpool"
}

# Health Probe for the Load Balancer (HTTP on port 80)
resource "azurerm_lb_probe" "http_probe" {
  loadbalancer_id     = azurerm_lb.lb.id
  name                = "${var.vm_name_prefix}-http-probe"
  port                = 80
  protocol            = "Http"
  request_path        = "/" # Nginx serves default page at root
  interval_in_seconds = 5   # How often to probe
  number_of_probes    = 2   # Number of consecutive probes to determine health status
}

# Load Balancing Rule (HTTP traffic on port 80)
resource "azurerm_lb_rule" "http_rule" {
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "${var.vm_name_prefix}-http-lb-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80 # Port on the backend VMs
  frontend_ip_configuration_name = azurerm_lb.lb.frontend_ip_configuration[0].name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.bap.id]
  probe_id                       = azurerm_lb_probe.http_probe.id
  enable_floating_ip             = false # Typically false for this scenario
  idle_timeout_in_minutes        = 4
  load_distribution              = "Default" # Default is 5-tuple hash
}

# --- Virtual Machine and related resources (using count) ---

# Network Interfaces (one per VM)
resource "azurerm_network_interface" "nic" {
  count               = var.vm_count
  name                = "${var.vm_name_prefix}-nic-${count.index}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "${var.vm_name_prefix}-ipconfig-${count.index}"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    # No public_ip_address_id here; VMs are behind the Load Balancer
  }

  tags = {
    environment = "dev"
    project     = "azure-iac-multi-vm-lb"
    instance    = count.index
  }
}

# Associate NICs with the Load Balancer Backend Pool
resource "azurerm_network_interface_backend_address_pool_association" "nic_lb_assoc" {
  count                   = var.vm_count
  network_interface_id    = azurerm_network_interface.nic[count.index].id
  ip_configuration_name   = azurerm_network_interface.nic[count.index].ip_configuration[0].name # Ensure this matches the name in nic's ip_configuration
  backend_address_pool_id = azurerm_lb_backend_address_pool.bap.id
}

# Associate Network Security Group with each Network Interface
resource "azurerm_network_interface_security_group_association" "nsg_association" {
  count                     = var.vm_count
  network_interface_id      = azurerm_network_interface.nic[count.index].id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Linux Virtual Machines
resource "azurerm_linux_virtual_machine" "vm" {
  count                 = var.vm_count
  name                  = "${var.vm_name_prefix}-${count.index}"
  resource_group_name   = data.azurerm_resource_group.rg.name
  location              = data.azurerm_resource_group.rg.location
  size                  = var.vm_size
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.nic[count.index].id]
  availability_set_id   = azurerm_availability_set.avset.id # Associate with Availability Set

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = var.vm_image_publisher
    offer     = var.vm_image_offer
    sku       = var.vm_image_sku
    version   = var.vm_image_version
  }

  custom_data = filebase64("${path.module}/user_data.sh") # Same user_data for all VMs

  tags = {
    environment = "dev"
    project     = "azure-iac-multi-vm-lb" # Updated project tag
    instance    = count.index
  }
}
