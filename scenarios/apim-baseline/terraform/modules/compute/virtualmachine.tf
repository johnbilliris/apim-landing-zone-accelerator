variable "resource_group_name" {
  type = string
}

variable "location" {
  type    = string
  default = "australiaeast"
}

variable "subnet_id" {
  type = string
}

variable "vm_name" {
  type    = string
  default = "vm1"
}

variable "vm_size" {
  type    = string
  default = "Standard_D2s_v3"
}

variable "admin_username" {
  type = string
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "os_disk_storage_account_type" {
  type    = string
  default = "Standard_LRS"
}

variable "tags" {
  type    = map(string)
  default = {}
}

resource "azurerm_network_interface" "vm_nic" {
  name                = "${var.vm_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig1"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.subnet_id
  }
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                = var.vm_name
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  tags                = var.tags

  network_interface_ids = [
    azurerm_network_interface.vm_nic.id,
  ]

  os_disk {
    name                 = "${var.vm_name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_storage_account_type
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-smalldisk"
    version   = "latest"
  }

  boot_diagnostics {}
}

output "id" {
  value = azurerm_windows_virtual_machine.vm.id
}

output "resource_group_name" {
  value = var.resource_group_name
}

output "name" {
  value = azurerm_windows_virtual_machine.vm.name
}

output "location" {
  value = azurerm_windows_virtual_machine.vm.location
}


