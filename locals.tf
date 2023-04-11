locals { 
  resource_group_name ="Env-Ressource-Group"
  location = "West Europe"
  ag_inbound_ports_map = {
    "100" : "80", 
    "110" : "443",
    "130" : "65200-65535"
  } 

#comment test
  frontend_port_name             = "${azurerm_virtual_network.Env-Vnet.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.Env-Vnet.name}-feip"
  listener_name                  = "${azurerm_virtual_network.Env-Vnet.name}-httplstn"
  request_routing_rule1_name      = "${azurerm_virtual_network.Env-Vnet.name}-rqrt-1"
  backend_address_pool_name_app1      = "${azurerm_virtual_network.Env-Vnet.name}-beap-app1"
  http_setting_name_app1             = "${azurerm_virtual_network.Env-Vnet.name}-be-htst-app1"
  probe_name_app1                = "${azurerm_virtual_network.Env-Vnet.name}-be-probe-app1"

}

