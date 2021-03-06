# Manages a Managed Kubernetes Cluster
resource "azurerm_kubernetes_cluster" "main" {

  name = var.cluster_name

  location = var.location

  resource_group_name = var.resource_group_name
  
  node_resource_group = var.node_resource_group

  kubernetes_version = var.kubernetes_version
  
  dns_prefix = var.cluster_dns_prefix

  service_principal {
    client_id     = var.service_principal_id
    client_secret = var.service_principal_secret
  }

  # The default nodepool
  default_node_pool {
    name                = "default"
    vm_size             = lookup(var.node_pool_default, "vm_size", "Standard_DS1_v2")
    enable_auto_scaling = lookup(var.node_pool_default, "enable_auto_scaling", true)
    node_count          = lookup(var.node_pool_default, "node_count", 1)
    min_count           = lookup(var.node_pool_default, "node_min_count", null)
    max_count           = lookup(var.node_pool_default, "node_max_count", null)
    max_pods       = lookup(var.node_pool_default, "max_pods", null)
    vnet_subnet_id = var.cluster_subnet_id
    upgrade_settings {
      max_surge = "33%"
    }
  }

  network_profile {
    network_plugin     = var.cluster_network_plugin
    dns_service_ip     = var.cluster_dns_service_ip
    docker_bridge_cidr = var.cluster_docker_bridge_cidr
    service_cidr       = var.cluster_service_cidr    
    
    load_balancer_sku = "standard"

    # Use a single IP for outbound traffic
    load_balancer_profile {
      outbound_ip_address_ids = [azurerm_public_ip.outbound.id]
    }
  }

  addon_profile {
    http_application_routing {
      enabled = false
    }
    kube_dashboard {
      enabled = false
    }
    oms_agent {
      enabled = false
    }
  }

  tags = var.tags

  depends_on = [azurerm_public_ip.outbound]
}

# The cluster additional node pools.
resource "azurerm_kubernetes_cluster_node_pool" "additional" {
  for_each = var.node_pool_additionals

  # The name of the node pool.
  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = lookup(each.value, "vm_size", "Standard_F16s_v2")
  enable_auto_scaling   = true
  node_count            = lookup(each.value, "node_min_count", 1)
  min_count             = lookup(each.value, "node_min_count", 1)
  max_count             = lookup(each.value, "node_max_count", 8)
  node_taints           = lookup(each.value, "node_taints", null)
  max_pods              = lookup(each.value, "max_pods", null)
  vnet_subnet_id        = var.cluster_subnet_id

  lifecycle {
    ignore_changes = [node_count]
  }
  tags = var.tags
}

# The public IP to use as outbound IP form AKS managed LoadBalancer.
resource "azurerm_public_ip" "outbound" {
  name                = var.cluster_outbound_ip_name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"

  # Standard sku required as it will be used by standard LoadBalancer.
  sku = "Standard"
 
  tags = var.tags
}
