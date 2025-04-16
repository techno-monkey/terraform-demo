resource "azurerm_resource_group" "azure_k8s" {
  location = var.location
  name     = local.common_name
  tags     = var.tags
}


resource "azurerm_container_registry" "k8s_acr" {
  location            = var.location
  name                = var.acr
  resource_group_name = azurerm_resource_group.azure_k8s.name
  sku                 = "Premium"
}





resource "random_id" "workspace" {
  byte_length = 8

}

resource "azurerm_log_analytics_workspace" "azure_workspace" {
  location            = var.location
  name                = "k8s-workspace-${random_id.workspace.hex}"
  resource_group_name = azurerm_resource_group.azure_k8s.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_log_analytics_solution" "azure_logsolution" {
  location              = var.location
  resource_group_name   = azurerm_resource_group.azure_k8s.name
  solution_name         = "ContainerInsights"
  workspace_name        = azurerm_log_analytics_workspace.azure_workspace.name
  workspace_resource_id = azurerm_log_analytics_workspace.azure_workspace.id
  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

resource "azurerm_virtual_network" "vnet" {
  address_space       = [element(var.address_space, 0)]
  location            = var.location
  name                = "${local.common_name}-vnet"
  resource_group_name = azurerm_resource_group.azure_k8s.name
}

resource "azurerm_subnet" "subnet" {
  address_prefixes     = [element(var.address_space, 1)]
  name                 = "${local.common_name}-subnet"
  resource_group_name  = azurerm_resource_group.azure_k8s.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azurerm_public_ip" "public_ip" {
  location            = var.location
  name                = "${local.common_name}-public_ip"
  resource_group_name = azurerm_resource_group.azure_k8s.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_kubernetes_cluster" "k8s_cluster" {
  dns_prefix          = var.dns_prefix
  location            = var.location
  name                = var.aks_cluster_name
  resource_group_name = azurerm_resource_group.azure_k8s.name
  kubernetes_version  = var.kubernetes_version
  default_node_pool {
    name       = var.agent_poolname
    node_count = var.agent_count
    vm_size    = var.agent_vm_size
    zones      = ["3"]
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    network_policy    = "azure"
  }

  service_principal {
    client_id     = var.client_id
    client_secret = var.client_secret
  }

  role_based_access_control_enabled = true

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_solution.azure_logsolution.workspace_resource_id
  }

  lifecycle {
    ignore_changes = [
      windows_profile,
      default_node_pool
    ]
  }

  tags = var.tags
}