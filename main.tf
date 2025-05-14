# Get a reference to the existing Resource Group
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# Create an Availability Set for the VMs
resource "azurerm_availability_set" "avset" {
  name                         = var.availability_set_name
  location                     = data.azurerm_resource_group.rg.location
  resource_group_name          = data.azurerm_resource_group.rg.name
  platform_fault_domain_count  = 2 # Number of fault domains, can be 2 or 3 for most regions
  platform_update_domain_count = 5 # Number of update domains
  tags = {
    environment = "dev"
    project     = "azure-iac-vm"
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
    project     = "azure-iac-vm"
  }
}

# Create a Subnet within the VNet
resource "azurerm_subnet" "subnet" {
  name                 = "${var.vm_name_prefix}-subnet"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet_address_prefix
}

# Create a Network Security Group (NSG) - This will be applied to each VM's NIC
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
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTPS"
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
    project     = "azure-iac-vm"
  }
}


# Create Public IP Addresses (one for each VM)
resource "azurerm_public_ip" "pip" {
  count               = var.vm_count
  name                = "${var.vm_name_prefix}-pip-${count.index}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags = {
    environment = "dev"
    project     = "azure-iac-vm"
    instance    = count.index
  }
}

# Create Network Interfaces (one for each VM)
resource "azurerm_network_interface" "nic" {
  count               = var.vm_count
  name                = "${var.vm_name_prefix}-nic-${count.index}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "${var.vm_name_prefix}-ipconfig-${count.index}"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip[count.index].id # Associate this NIC with its dedicated Public IP
  }

  tags = {
    environment = "dev"
    project     = "azure-iac-vm"
    instance    = count.index
  }
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
    project     = "azure-iac-vm"
    instance    = count.index
  }
}