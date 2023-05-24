variable "resource_group_name" {
  description = "Name of the resource group"
}

variable "location" {
  description = "Location of the resource group"
}

variable "vmadmin_username" {
    description = "Username for administrator"
}

variable "vm_size" {
    description = "Size of the Virutal Machine"
}

variable "vnet_cidr" {
    description = "Vnet CIDR for the resources to be created.  Eg: 192.168.0.0/16"
}

variable "subnet_cidr" {
    description = "Vnet CIDR for the resources to be created.  Eg: 192.168.0.0/16"
}

variable "vm_name" {
    description = "Virtual Machine with Azure VM accepted annotations."
}

variable "vm_source_image_offer" {
    description = "Vm image. Eg: Ubuntu"
}

variable "vm_sku" {
  description = "Sku of the VM image Eg:16.04-LTS"
}

variable "recovery_vault_name" {
    description = "Name of the Recovery service vault"
}

variable "owner_tag" {
  description = "Owner of the resource"
}

variable "env_tag" {
  description = "Environment Name in which resources will be deployed"
}
resource "azurerm_resource_group" "resource_group" {

name = var.resource_group_name

 location = var.location

tags = {

 Owner = var.owner_tag

 Env = var.env_tag

 }
}
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.vm_name}-vnet"
  address_space       = [var.vnet_cidr]
  location            = var.location
  resource_group_name = var.resource_group_name
  tags = {
    Owner = var.owner_tag
    Env   = var.env_tag
  }
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.vm_name}-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_cidr]
    depends_on = [
    resource.azurerm_virtual_network.vnet
  ]
}

resource "azurerm_public_ip" "public_ip" {
  name                = "${var.vm_name}-publicip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  tags = {
    Owner = var.owner_tag
    Env   = var.env_tag
  }
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.vm_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_configuration {
    name                          = "${var.vm_name}-subnet"
    primary                       = true
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
  tags = {
    Owner = var.owner_tag
    Env   = var.env_tag
  }
  depends_on = [
    resource.azurerm_subnet.subnet
  ]
}

resource "tls_private_key" "vm_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_linux_virtual_machine" "deployment_machine" {
  name                = var.vm_name
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size //"Standard_F2"
  admin_username      = var.vmadmin_username
  tags = {
    Owner = var.owner_tag
    Env   = var.env_tag
  }
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  admin_ssh_key {
    username   = var.vmadmin_username
    public_key = tls_private_key.vm_ssh.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = var.vm_source_image_offer
    sku       = var.vm_sku // "16.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_network_security_group" "vm_nsg" {
  name                = "${var.vm_name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
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
  tags = {
    Owner = var.owner_tag
    Env   = var.env_tag
  }
}

resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
  depends_on = [
    resource.azurerm_network_security_group.vm_nsg,
    resource.azurerm_network_interface.nic
  ]
}

output "tls_private_key" {
  value     = tls_private_key.vm_ssh.private_key_pem
  sensitive = true
}
output "vm_name" {
  value = azurerm_linux_virtual_machine.deployment_machine.name
}

output "public_ip_address" {
  value = azurerm_linux_virtual_machine.deployment_machine.public_ip_address
}
