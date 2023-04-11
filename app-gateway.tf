
# Resource-6: Azure Application Gateway 

resource "azurerm_application_gateway" "app-gateway" {
  name                = "app-gateway"
  resource_group_name = local.resource_group_name
  location            = local.location

# SKU: Standard_v2 
  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    #capacity = 2
  }
  autoscale_configuration {
    min_capacity = 0
    max_capacity = 10
  }  

  gateway_ip_configuration {
    name      = "gateway-ip-configuration"
    subnet_id = azurerm_subnet.agsubnet.id
  }

  # Frontend Configs
  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.app-gateway-pip.id    
  }

  # Listener: HTTP 80
  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  # App1 Configs
  backend_address_pool {
    name = local.backend_address_pool_name_app1
  }
  backend_http_settings {
    name                  = local.http_setting_name_app1
    cookie_based_affinity = "Disabled"
    #path                  = "/app1/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
    probe_name            = local.probe_name_app1
  }
  probe {
    name                = local.probe_name_app1
    host                = "127.0.0.1"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    protocol            = "Http"
    port                = 80
    path                = "/"
  }   

  # Routing Rule

  request_routing_rule {
    name                       = local.request_routing_rule1_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name_app1
    backend_http_settings_name = local.http_setting_name_app1
  }
   tags = {
    environment = "PFE2023_CHAKKOUR_AIT_AHMED"
  }
  
}


resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "ELK_association" {
    network_interface_id    = azurerm_network_interface.ELK-Nic.id
    ip_configuration_name   = "elk-ip"
    backend_address_pool_id = tolist(azurerm_application_gateway.app-gateway.backend_address_pool).0.id
}
resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "Grafana_association" {
    network_interface_id    = azurerm_network_interface.Grafana-Nic.id
    ip_configuration_name   = "grafana-ip"
    backend_address_pool_id = tolist(azurerm_application_gateway.app-gateway.backend_address_pool).0.id
}
/*
resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "Grafana_association" {
    network_interface_id    = azurerm_network_interface.Grafana-Nic.id
    ip_configuration_name   = "grafana-ip"
    backend_address_pool_id = tolist(azurerm_application_gateway.app-gateway.backend_address_pool).0.id
}



 resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "nic_association" {
  network_interface_id    = join(",", [azurerm_network_interface.ELK-Nic.id , azurerm_network_interface.Grafana-Nic.id])
  ip_configuration_name   = join(",", ["elk-ip", "grafana-ip"])
  backend_address_pool_id = tolist(azurerm_application_gateway.app-gateway.backend_address_pool).0.id
}

*/