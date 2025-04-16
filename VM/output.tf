output "vm_public_ip" {
  value = azurerm_network_interface.vm_network_interface.private_ip_address
  description = "The private IP address of the virtual machine"
}

output "resource_group_name" {
  value = azurerm_resource_group.azure_vm.name
  description = "The name of the resource group"
}