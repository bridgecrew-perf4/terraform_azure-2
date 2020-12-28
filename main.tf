provider "azurerm" {
    version = "2.2.0"
    features {}
}


resource "azurerm_resource_group" "web-rg" {
  name     = var.web_server_rg
  location = var.web_server_location
}

resource "azurerm_virtual_network" "web_server_vnet" {
  name                = "${var.resource_prefix}-vnet"
  location            = var.web_server_location
  resource_group_name = azurerm_resource_group.web-rg.name
  address_space       = [var.web_server_address_space]
  depends_on          = [azurerm_resource_group.web-rg]
}

resource "azurerm_subnet" "web_server_subnet" {
  name                 = "${var.resource_prefix}-subnet"
  resource_group_name  = azurerm_resource_group.web-rg.name
  virtual_network_name = azurerm_virtual_network.web_server_vnet.name
  address_prefix       = var.web_server_subnet
}

resource "azurerm_network_interface" "web_server_nic" {
  name                 = "${var.resource_prefix}-nic"
  location             = var.web_server_location
  resource_group_name  = azurerm_resource_group.web-rg.name

  ip_configuration {
    name                          = "${var.resource_prefix}-ip"
    subnet_id                     = azurerm_subnet.web_server_subnet.id
    private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_public_ip" "web_server_public_ip" {
  name                 = "${var.resource_prefix}-public-ip"
  location             = var.web_server_location
  resource_group_name  = azurerm_resource_group.web-rg.name
# If env variable set to production, allocation method will be Static, otherwide Dynamic
  allocation_method    = var.env == "production" ? "Static" : "Dynamic"
}

resource "azurerm_network_security_group" "web_server_nsg" {
  name                 = "${var.resource_prefix}-nsg"
  location             = var.web_server_location
  resource_group_name  = azurerm_resource_group.web-rg.name
}

resource "azurerm_network_security_rule" "web_server_nsg_rule_rdp" {
  name = "RDP Inbound"
  priority = 100
  direction = "Inbound"
  access = "Allow"
  protocol = "Tcp"
  source_port_range = "*"
  destination_port_range = "3389"
  source_address_prefix = "*"
  destination_address_prefix = "*"
  resource_group_name  = azurerm_resource_group.web-rg.name
  network_security_group_name = azurerm_network_security_group.web_server_nsg.name
}

