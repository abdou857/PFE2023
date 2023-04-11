terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "Env-Ressource-Group" {
  name     = "Env-Ressource-Group"
  location = "West Europe"
  tags = {
    environment="PFE2023_CHAKKOUR_AIT_AHMED"
  }
}

# Create a virtual network within the resource group

resource "azurerm_virtual_network" "Env-Vnet" {
  name                = "Env-Vnet"
  resource_group_name = local.resource_group_name
  location            = local.location
  address_space       = ["10.0.0.0/16"]
}

# create Subnets

resource "azurerm_subnet" "agsubnet" {
  name                 = "agsubnet"
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.Env-Vnet.name
  address_prefixes     = ["10.0.0.0/24"] 
}

resource "azurerm_subnet" "admin-Subnet" {
  name                 = "admin-Subnet"
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.Env-Vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  
}
resource "azurerm_subnet" "monitoring-Subnet" {
  name                 = "monitoring-Subnet"
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.Env-Vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

#azure security group
#admin NSG
resource "azurerm_network_security_group" "Admin-Nsg" {
  name                = "Admin-Nsg"
  location            = local.location
  resource_group_name = local.resource_group_name

  security_rule {
    name                       = "Allow-ssh"
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
    environment="PFE2023_CHAKKOUR_AIT_AHMED"
  }
}

#monitoring NSG

resource "azurerm_network_security_group" "Monitoring-Nsg" {
  name                = "Monitoring-Nsg"
  location            = local.location
  resource_group_name = local.resource_group_name

  security_rule {
    name                       = "allow-ssh"
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
    environment="PFE2023_CHAKKOUR_AIT_AHMED"
  }
}

# Resource-3: Create Network Security Group (NSG)

resource "azurerm_network_security_group" "ag_subnet_nsg" {
  name                = "ag_subnet_nsg"
  location            = local.location
  resource_group_name = local.resource_group_name
  tags = {
    environment="PFE2023_CHAKKOUR_AIT_AHMED"
  }
}
resource "azurerm_network_security_rule" "ag_nsg_rule" {
  for_each = local.ag_inbound_ports_map
  name                        = "Allow-${each.value}"
  priority                    = each.key
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = each.value 
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = local.resource_group_name
  network_security_group_name = azurerm_network_security_group.ag_subnet_nsg.name
 }

  

#association des NSG au sunets

resource "azurerm_subnet_network_security_group_association" "Nsg-Subnet-Admin" {
  subnet_id                 = azurerm_subnet.admin-Subnet.id
  network_security_group_id = azurerm_network_security_group.Admin-Nsg.id
}

resource "azurerm_subnet_network_security_group_association" "Nsg-Subnet-Monitoring" {
  subnet_id                 = azurerm_subnet.monitoring-Subnet.id
  network_security_group_id = azurerm_network_security_group.Monitoring-Nsg.id
}
resource "azurerm_subnet_network_security_group_association" "ag_subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.agsubnet.id
  network_security_group_id = azurerm_network_security_group.ag_subnet_nsg.id
}

#creation of the public IPs

resource "azurerm_public_ip" "app-gateway-pip" {
  name                = "app-gateway-pip"
  resource_group_name = local.resource_group_name
  location            = local.location
  allocation_method   = "Static"
  domain_name_label = "dns-pip-traff-manager"
  sku = "Standard"
   tags = {
    environment = "PFE2023_CHAKKOUR_AIT_AHMED"
  }
}

resource "azurerm_public_ip" "admin-vm-pip" {
  name                = "admin-vm-pip"
  resource_group_name = local.resource_group_name
  location            = local.location
  allocation_method   = "Static"
   tags = {
    environment = "PFE2023_CHAKKOUR_AIT_AHMED"
  }
}


#### creation des vm ####

# 1-interfece reseau d la vm NIC ou on va attacher la publique IP

        ########## admin nic 
resource "azurerm_network_interface" "admin-Nic" {
  name                = "admin-nic"
  location            = local.location
  resource_group_name = local.resource_group_name

  ip_configuration {
    name                          = "admin-pub-ip"
    subnet_id                     = azurerm_subnet.admin-Subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = "${azurerm_public_ip.admin-vm-pip.id}"
  }
   tags = {
    environment = "PFE2023_CHAKKOUR_AIT_AHMED"
  }
}
       ###### ELK VL SUBNET
resource "azurerm_network_interface" "ELK-Nic" {
  name                = "ELK-nic"
  location            = local.location
  resource_group_name = local.resource_group_name

  ip_configuration {
    name                          = "elk-ip"
    subnet_id                     = azurerm_subnet.monitoring-Subnet.id
    private_ip_address_allocation = "Dynamic"
  }
   tags = {
    environment = "PFE2023_CHAKKOUR_AIT_AHMED"
  }
}

    #### Grafana NIC
resource "azurerm_network_interface" "Grafana-Nic" {
  name                = "Grafana-nic"
  location            = local.location
  resource_group_name = local.resource_group_name

   tags = {
    environment = "PFE2023_CHAKKOUR_AIT_AHMED"
  }

  ip_configuration {
    name                          = "grafana-ip"
    subnet_id                     = azurerm_subnet.monitoring-Subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}


#### 2- creation des vms

    #VM ADMIN

resource "azurerm_virtual_machine" "admin-vm" {
  name                  = "admin-vm"
  location              = local.location
  resource_group_name   = local.resource_group_name
  network_interface_ids = [azurerm_network_interface.admin-Nic.id]
  vm_size               = "Standard_B1s"



  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "admin-vm-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "PFE2023_CHAKKOUR_AIT_AHMED"
  }
}

    ################ vm ELK 
resource "azurerm_virtual_machine" "ELK-vm" {
  name                  = "ELK-vm"
  location              = local.location
  resource_group_name   = local.resource_group_name
  network_interface_ids = [azurerm_network_interface.ELK-Nic.id]
  vm_size               = "Standard_B1s"



  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "elk-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "PFE2023_CHAKKOUR_AIT_AHMED"
  }
}

    ############## grafana vm
resource "azurerm_virtual_machine" "grafana-vm" {
  name                  = "grafana-vm"
  location              = local.location
  resource_group_name   = local.resource_group_name
  network_interface_ids = [azurerm_network_interface.Grafana-Nic.id]
  vm_size               = "Standard_B1s"



  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "grafana-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "PFE2023_CHAKKOUR_AIT_AHMED"
  }
}










 
 






