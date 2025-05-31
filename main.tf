terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.0"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "example-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "example-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "example-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-ICMP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-RDP"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "assoc" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_public_ip" "external_lb_ip" {
  name                = "external-lb-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "external_lb" {
  name                = "external-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicFrontEnd"
    public_ip_address_id = azurerm_public_ip.external_lb_ip.id
  }
}

resource "azurerm_lb_backend_address_pool" "external_backend" {
  name                = "external-backend-pool"
  loadbalancer_id     = azurerm_lb.external_lb.id
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_lb_probe" "external_probe" {
  name                = "http-probe"
  loadbalancer_id     = azurerm_lb.external_lb.id
  protocol            = "Tcp"
  port                = 80
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "external_rule" {
  name                           = "http-rule"
  loadbalancer_id                = azurerm_lb.external_lb.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicFrontEnd"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.external_backend.id
  probe_id                      = azurerm_lb_probe.external_probe.id
}

# Internal Load Balancer

resource "azurerm_lb" "internal_lb" {
  name                = "internal-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "PrivateFrontEnd"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address            = "10.0.1.100"
    private_ip_address_allocation = "Static"
  }
}

resource "azurerm_lb_backend_address_pool" "internal_backend" {
  name                = "internal-backend-pool"
  loadbalancer_id     = azurerm_lb.internal_lb.id
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_lb_probe" "internal_probe" {
  name                = "tcp-probe"
  loadbalancer_id     = azurerm_lb.internal_lb.id
  protocol            = "Tcp"
  port                = 80
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "internal_rule" {
  name                           = "internal-rule"
  loadbalancer_id                = azurerm_lb.internal_lb.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PrivateFrontEnd"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.internal_backend.id
  probe_id                      = azurerm_lb_probe.internal_probe.id
}

# Network Interfaces and VMs

resource "azurerm_network_interface" "linux_nic" {
  name                = "linux-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet.id

  ip_configuration {
    name                          = "internal"
    private_ip_address_allocation = "Dynamic"
    load_balancer_backend_address_pools_ids = [
      azurerm_lb_backend_address_pool.external_backend.id,
      azurerm_lb_backend_address_pool.internal_backend.id,
    ]
  }
}

resource "azurerm_network_interface" "windows_nic" {
  name                = "windows-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet.id

  ip_configuration {
    name                          = "internal"
    private_ip_address_allocation = "Dynamic"
    load_balancer_backend_address_pools_ids = [
      azurerm_lb_backend_address_pool.external_backend.id,
      azurerm_lb_backend_address_pool.internal_backend.id,
    ]
  }
}

resource "azurerm_linux_virtual_machine" "linux_vm" {
  name                = "linux-vm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_B1s"
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  network_interface_ids = [azurerm_network_interface.linux_nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "20_04-lts"
    version   = "latest"
  }

  disable_password_authentication = false
}

resource "azurerm_windows_virtual_machine" "windows_vm" {
  name                = "windows-vm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_B1s"
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  network_interface_ids = [azurerm_network_interface.windows_nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}
