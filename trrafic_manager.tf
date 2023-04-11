
resource "azurerm_traffic_manager_profile" "traff-manager" {
  name                   = "traff-manager"
  resource_group_name    = local.resource_group_name
  traffic_routing_method = "Weighted"

  dns_config {
    relative_name = "traff-manager"
    ttl           = 100
  }

  monitor_config {
    protocol                     = "HTTP"
    port                         = 80
    path                         = "/"
    interval_in_seconds          = 30
    timeout_in_seconds           = 9
    tolerated_number_of_failures = 3
  }
   tags = {
    environment = "PFE2023_CHAKKOUR_AIT_AHMED"
  }
}

resource "azurerm_traffic_manager_azure_endpoint" "traff-manager-endpoint" {
  name               = "traff-manager-endpoint"
  profile_id         = azurerm_traffic_manager_profile.traff-manager.id
  weight             = 100
  target_resource_id = azurerm_public_ip.app-gateway-pip.id
}
