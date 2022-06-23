resource "azurerm_resource_group" "aks_rg" {
  name     = "aks-getting-started"
  location = var.location
}


## aks cluster ##
resource "azurerm_kubernetes_cluster" "demo-aks-cluster" {
  name                = "aks-getting-started"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  node_resource_group = azurerm_resource_group.aks_rg.name
  dns_prefix          = azurerm_resource_group.aks_rg.name
  kubernetes_version  = var.kubernetes_version


  depends_on = [
    azurerm_resource_group.aks_rg
  ]

#   identity {
#     type = "SystemAssigned"
#   }

  default_node_pool {
    name       = "systempool"
    vm_size    = "Standard_DS2_v2"
    node_count = 1
  }

  service_principal {
    client_id     = var.serviceprinciple_id
    client_secret = var.serviceprinciple_key
  }

  linux_profile {
    admin_username = "azureuser"
    ssh_key {
      key_data = var.ssh_key
    }
  }

  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "standard"
  }

}