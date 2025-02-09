# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "RabbitMQ-Upwork"
  location = local.location
}

# Network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-ansible"
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.location
  address_space       = ["10.0.20.0/25"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet-ansible"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.20.0/27"]
}

# NSG
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-ansible"
  location            = local.location
  resource_group_name = azurerm_resource_group.rg.name
  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "RDP"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "WinRM"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["5985", "5986"]
    source_address_prefix      = "4.178.170.27"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "RabbitMQ_Cluster_Communication"
    priority                   = 310
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["4369", "25672", "35672-35682"] # EPMD, inter-node and CLI tool communication
    source_address_prefix      = "10.0.20.0/25"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "RabbitMQ_Client_Ports"
    priority                   = 320
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["5672", "15672"] # AMQP and management interface
    source_address_prefix      = "4.178.170.27"
    destination_address_prefix = "*"
  }
}

# Public IPs
resource "azurerm_public_ip" "pip" {
  for_each            = local.vms
  name                = "pip-${each.value.name}"
  location            = local.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Network Interfaces
resource "azurerm_network_interface" "nic" {
  for_each            = local.vms
  name                = "nic-${each.value.name}"
  location            = local.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip[each.key].id
  }
}

# Linux VMs
resource "azurerm_linux_virtual_machine" "vm_linux" {
  for_each = {
    for k, v in local.vms : k => v
    if v.os == "linux"
  }
  name                = each.value.name
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.location
  size                = each.value.size
  admin_username      = "Ayoub"
  network_interface_ids = [
    azurerm_network_interface.nic[each.key].id
  ]
  admin_ssh_key {
    username   = "Ayoub"
    public_key = file("~/.ssh/id_rsa.pub")
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  plan {
    name      = "rocky-linux-9-4"
    publisher = "procomputers"
    product   = "rocky-linux-9-4"
  }
  source_image_reference {
    publisher = "procomputers"
    offer     = "rocky-linux-9-4"
    sku       = "rocky-linux-9-4"
    version   = "latest"
  }
}

# Windows VMs
resource "azurerm_windows_virtual_machine" "vm_windows" {
  for_each = {
    for k, v in local.vms : k => v
    if v.os == "windows"
  }

  name                = each.value.name
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.location
  size                = each.value.size
  admin_username      = "Ayoub"
  admin_password      = "SALE-hay1993"

  network_interface_ids = [
    azurerm_network_interface.nic[each.key].id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
}

# NSG Associations
resource "azurerm_network_interface_security_group_association" "nsg_association" {
  for_each                  = local.vms
  network_interface_id      = azurerm_network_interface.nic[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg.id
}