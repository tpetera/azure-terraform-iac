# Get a reference to the existing Resource Group
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# Create an Availability Set for the VMs
resource "azurerm_availability_set" "avset" {
  name                         = var.availability_set_name
  location                     = data.azurerm_resource_group.rg.location
  resource_group_name          = data.azurerm_resource_group.rg.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 5
  tags = {
    environment = "dev"
    project     = "azure-iac-appgw-waf" # Updated project tag
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
    project     = "azure-iac-appgw-waf"
  }
}

# Create a Subnet for the Virtual Machines
resource "azurerm_subnet" "vm_subnet" {
  name                 = "${var.vm_name_prefix}-snet" # VM Subnet
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.vm_subnet_address_prefix
}

# Create a dedicated Subnet for the Application Gateway
resource "azurerm_subnet" "app_gateway_subnet" {
  name                 = "AppGatewaySubnet" # Specific name often required or recommended
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.app_gateway_subnet_address_prefix]
}

# Create a Network Security Group (NSG) for the VM Subnet
# This NSG will allow HTTP from the App Gateway Subnet and SSH
resource "azurerm_network_security_group" "vm_nsg" {
  name                = "${var.vm_name_prefix}-vm-nsg"
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
    source_address_prefix      = "Internet" # For SSH via Bastion/Jumpbox. Restrict further in production.
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTPFromAppGateway"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = var.app_gateway_subnet_address_prefix # Allow from App Gateway Subnet
    destination_address_prefix = "*"
  }
  # No public HTTPS rule here as SSL terminates at App Gateway for now

  tags = {
    environment = "dev"
    project     = "azure-iac-appgw-waf"
  }
}

# --- Azure Application Gateway & WAF Configuration ---

# Public IP for the Application Gateway
resource "azurerm_public_ip" "app_gateway_pip" {
  name                = var.app_gateway_public_ip_name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard" # Required for WAF_v2 SKU of Application Gateway
  tags = {
    environment = "dev"
    project     = "azure-iac-appgw-waf"
  }
}

# WAF Policy
resource "azurerm_web_application_firewall_policy" "waf_policy" {
  name                = var.waf_policy_name
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location

  policy_settings {
    enabled            = true
    mode               = "Prevention" # Can be "Detection" or "Prevention"
    file_upload_limit_in_mb = 100
    request_body_check = true
    max_request_body_size_in_kb = 128
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2" # Or "3.1", "3.0". Check Azure documentation for latest recommended.
    }
  }
  tags = {
    environment = "dev"
    project     = "azure-iac-appgw-waf"
  }
}

# Application Gateway
resource "azurerm_application_gateway" "app_gateway" {
  name                = var.app_gateway_name
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location

  sku {
    name     = "WAF_v2" # SKU that includes WAF
    tier     = "WAF_v2"
    capacity = 2 # Default capacity units, adjust based on expected load
  }

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = azurerm_subnet.app_gateway_subnet.id
  }

  frontend_port {
    name = "httpPort"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "appGatewayFrontendIp"
    public_ip_address_id = azurerm_public_ip.app_gateway_pip.id
  }

  backend_address_pool {
    name = "appGatewayBackendPool"
  }

  backend_http_settings {
    name                  = "httpBackendSettings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 20     # Seconds
    probe_name            = "httpProbe" # Reference the probe defined below
  }

  http_listener {
    name                           = "httpListener"
    frontend_ip_configuration_name = "appGatewayFrontendIp"
    frontend_port_name             = "httpPort"
    protocol                       = "Http"
    # If using a dedicated WAF policy resource, you can associate it here or at the gateway level.
    # firewall_policy_id = azurerm_web_application_firewall_policy.waf_policy.id # Option 1: Associate at listener level
  }

  request_routing_rule {
    name                       = "httpRoutingRule"
    rule_type                  = "Basic"
    http_listener_name         = "httpListener"
    backend_address_pool_name  = "appGatewayBackendPool"
    backend_http_settings_name = "httpBackendSettings"
    priority                   = 100
  }

  probe {
    name                = "httpProbe"
    protocol            = "Http"
    host                = "127.0.0.1"
    path                = "/"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
  }

  # Associate the dedicated WAF policy with the Application Gateway instance
  firewall_policy_id = azurerm_web_application_firewall_policy.waf_policy.id
  # NOTE: The inline 'waf_configuration' block has been removed from this resource
  # as we are using the 'firewall_policy_id' to link the separate WAF policy resource.

  tags = {
    environment = "dev"
    project     = "azure-iac-appgw-waf"
  }
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
    subnet_id                     = azurerm_subnet.vm_subnet.id # Ensure VMs are in the VM subnet
    private_ip_address_allocation = "Dynamic"
    # Association with App Gateway backend pool is now done via a separate resource
  }

  tags = {
    environment = "dev"
    project     = "azure-iac-appgw-waf"
    instance    = count.index
  }
}

# Associate each NIC's IP Configuration with the Application Gateway Backend Pool
resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "nic_appgw_assoc" {
  count                   = var.vm_count
  network_interface_id    = azurerm_network_interface.nic[count.index].id
  ip_configuration_name   = azurerm_network_interface.nic[count.index].ip_configuration[0].name
  backend_address_pool_id = azurerm_application_gateway.app_gateway.backend_address_pool[0].id
}

# Associate Network Security Group with each VM's Network Interface
resource "azurerm_network_interface_security_group_association" "vm_nsg_association" {
  count                     = var.vm_count
  network_interface_id      = azurerm_network_interface.nic[count.index].id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
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
  availability_set_id   = azurerm_availability_set.avset.id

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

  custom_data = filebase64("${path.module}/user_data.sh")

  tags = {
    environment = "dev"
    project     = "azure-iac-appgw-waf"
    instance    = count.index
  }
}
