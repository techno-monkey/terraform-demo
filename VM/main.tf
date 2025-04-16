resource "azurerm_resource_group" "azure_vm" {
  name     = local.common_name
  location = var.location   
  
}

resource "azurerm_virtual_network" "vm_vnet" {
    # Create a virtual network for the VM
    name = "${var.prefix}-vnet"
    address_space = ["10.0.0.0/24"]
    location = azurerm_resource_group.azure_vm.location
    resource_group_name = azurerm_resource_group.azure_vm.name
    tags = var.tags    
}

resource "azurerm_subnet" "vm_subnet" {
    # Create a subnet within the virtual network
    name = "${var.prefix}-subnet"
    resource_group_name = azurerm_resource_group.azure_vm.name
    virtual_network_name = azurerm_virtual_network.vm_vnet.name
    address_prefixes = ["10.0.0.16/28"]
}

resource "azurerm_public_ip" "vm_public_ip" {
    # Create a public IP address
    name                = "${var.prefix}-public-ip"
    location            = azurerm_resource_group.azure_vm.location
    resource_group_name = azurerm_resource_group.azure_vm.name
    allocation_method   = "Dynamic" # Use "Static" if you want a fixed IP
    sku                 = "Basic"  # Use "Standard" for advanced features
    tags                = var.tags
}

resource "azurerm_network_interface" "vm_network_interface" {
    # Create a network interface for the VM
    name = "${var.prefix}-nic"
    location = azurerm_resource_group.azure_vm.location
    resource_group_name = azurerm_resource_group.azure_vm.name
    ip_configuration {
        name = "${var.prefix}-ipconfig"
        subnet_id = azurerm_subnet.vm_subnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id = azurerm_public_ip.vm_public_ip.id
    }
    tags = var.tags    
}

resource "azurerm_network_security_group" "vm_nsg" {
    # Create a network security group to allow RDP
    name                = "${var.prefix}-nsg"
    location            = azurerm_resource_group.azure_vm.location
    resource_group_name = azurerm_resource_group.azure_vm.name
    tags                = var.tags

    security_rule {
        name                       = "Allow-RDP"
        priority                   = 1000
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3389" # RDP port
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}

resource "azurerm_network_interface_security_group_association" "vm_nic_nsg" {
    # Associate the NIC with the NSG
    network_interface_id      = azurerm_network_interface.vm_network_interface.id
    network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

resource "azurerm_virtual_machine" "vm_machine" {
    name = "${var.prefix}-vm"
    location = azurerm_resource_group.azure_vm.location
    resource_group_name = azurerm_resource_group.azure_vm.name
    network_interface_ids = [azurerm_network_interface.vm_network_interface.id]
    vm_size = var.vm_size
    
    storage_image_reference {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2019-Datacenter"
        version   = "latest"
    }

    storage_os_disk {
        name = "${var.prefix}-osdisk"
        caching = "ReadWrite"
        create_option = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

    os_profile {
        computer_name = "${var.prefix}-host"
        admin_username = "adminuser"
        admin_password = "Password1234!"
        #custom_data = base64encode(file("cloud-init.txt"))
        #You usually pass a cloud-init script to automatically install software, configure settings, etc.
        /* #cloud-config
            package_upgrade: true
            packages:
            - nginx
            runcmd:
            - systemctl start nginx
            */
    }
    os_profile_windows_config {
        provision_vm_agent = true
        enable_automatic_upgrades = true
    }

}