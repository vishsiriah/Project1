# Configure the Microsoft Azure Provider
provider "azurerm" {
  subscription_id = var.azure_provider_id.sub_id
  #client_id       = var.azure_provider_id.cli_id
  #client_secret   = var.azure_provider_id.cli_sec
  #tenant_id       = var.azure_provider_id.ten_id

  features {}
}

#resource "azurerm_resource_group" "main" {
#  name     = "Udacity-rg-vspg-aus"
# location = "Australia East"
#}

# Locate the existing resource group
data "azurerm_resource_group" "main" {
  name = var.az_rg
}
output "id" {
  value = data.azurerm_resource_group.main.id
}

# Locate the existing custom image
data "azurerm_image" "main" {
  name                = var.az_packer_image
  resource_group_name = var.az_rg
}

output "image_id" {
  value = "/subscriptions/05ea1b17-c7ce-4c8c-8075-789ae0384a3d/resourceGroups/Udacity-rg-vspg-aus/providers/Microsoft.Compute/images/Udactiy_project1_VS_image"
}

# Create a Network Security Group with some rules
resource "azurerm_network_security_group" "main" {
  name                = "my-SG"
  location            = var.infra_deployment_location
  resource_group_name = var.az_rg

  security_rule {
    name                       = "my-SGR"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create virtual network
resource "azurerm_virtual_network" "my-virtual-network" {
  name                = "my-network"
  address_space       = ["10.0.0.0/16"]
  location            = var.infra_deployment_location
  resource_group_name = var.az_rg
}

# Create subnet
resource "azurerm_subnet" "main" {
  name                 = "my-subnet"
  resource_group_name  = var.az_rg
  virtual_network_name = azurerm_virtual_network.my-virtual-network.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Create public IP
resource "azurerm_public_ip" "main" {
  name                = "my-public-ip"
  resource_group_name = var.az_rg
  location            = var.infra_deployment_location
  allocation_method   = "Static"

  tags = {
    environment = var.res_tag
  }
}

# Create network interface
resource "azurerm_network_interface" "my-network-interface" {
  count				        = var.counter
  name                = "my-nic${count.index}"
  location            = var.infra_deployment_location
  resource_group_name = var.az_rg

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    #public_ip_address_id          = azurerm_public_ip.main.id
  }
}

# Create network security association group
resource "azurerm_network_interface_security_group_association" "nsg_sec_as_group" {
  count                     = var.counter
  network_interface_id      = azurerm_network_interface.my-network-interface[count.index].id
  network_security_group_id = azurerm_network_security_group.main.id
}

# Create an availability set
resource "azurerm_availability_set" "main2" {
  name                = "udacity-aset"
  location            = var.infra_deployment_location
  resource_group_name = var.az_rg
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true

  tags = {
    environment = var.res_tag
  }
}

output "avid" {
  value = resource.azurerm_availability_set.main2.id
}

# Create a new Virtual Machine based on the custom Image
resource "azurerm_virtual_machine" "VM" {
  #for_each                        = toset(var.vm_name)
  count							               = var.counter
  name                             = "Udacity-vspg${count.index}"
  location                         = var.infra_deployment_location
  resource_group_name              = var.az_rg
  availability_set_id   		       = azurerm_availability_set.main2.id
  network_interface_ids            = [element(azurerm_network_interface.my-network-interface.*.id, count.index)]
  vm_size                          = "Standard_F2"
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    id = "${data.azurerm_image.main.id}"
  }

  storage_os_disk {
    name              = "Udacity-vspg${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
}

  os_profile {
    computer_name  = "Udacity-vspg${count.index}"
    admin_username = "devopsadmin"
    admin_password = "Cssladmin#2019"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
  
  tags = {
    environment = var.res_tag
  }
}

#Create Load balancer to balance the created VMs
resource "azurerm_public_ip" "public-ip" {
  name                = "PublicIPForLB"
  location            = var.infra_deployment_location
  resource_group_name = var.az_rg
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "app-lb" {
  name                = "VSPG-LoadBalancer"
  location            = var.infra_deployment_location
  resource_group_name = var.az_rg
  sku                 = "Standard"
# Create load balancer Frontend IP
  frontend_ip_configuration {
    name                 = "FrontEndIP"
    public_ip_address_id = azurerm_public_ip.public-ip.id
  }
  depends_on = [
    azurerm_public_ip.public-ip
  ]
}
# Create load balancer backend IP Pool
resource "azurerm_lb_backend_address_pool" "backendPoolA" {
  loadbalancer_id = azurerm_lb.app-lb.id
  name            = "BackEndAddressPool"
  depends_on = [
    azurerm_lb.app-lb
  ]
}

resource "azurerm_lb_backend_address_pool_address" "backend-address-pool" {
  count							               = var.counter
  name                             = "Udacity-vspg${count.index}"
  backend_address_pool_id          = azurerm_lb_backend_address_pool.backendPoolA.id
  virtual_network_id               = azurerm_virtual_network.my-virtual-network.id
  ip_address                       = azurerm_network_interface.my-network-interface[count.index].private_ip_address
  depends_on = [
    azurerm_lb_backend_address_pool.backendPoolA
  ]
}

resource azurerm_network_interface_backend_address_pool_association "az-nw-bk-ad-pool-as" {
  count                   = var.counter
  network_interface_id    = azurerm_network_interface.my-network-interface.*.id[count.index]
  ip_configuration_name   = azurerm_network_interface.my-network-interface.*.ip_configuration.0.name[count.index]
  backend_address_pool_id = azurerm_lb_backend_address_pool.backendPoolA.id
  depends_on = [
    azurerm_network_interface.my-network-interface
  ]
}

resource "azurerm_lb_probe" "health-probe" {
  loadbalancer_id     = azurerm_lb.app-lb.id
  name                = "health-probe"
  port                = 80
  depends_on = [
    azurerm_lb.app-lb
  ]
}

resource "azurerm_lb_rule" "az-lb-rule" {
  loadbalancer_id                = azurerm_lb.app-lb.id
  name                           = "az-lb-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "FrontEndIP"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backendPoolA.id]
  probe_id                       = azurerm_lb_probe.health-probe.id
  depends_on = [
    azurerm_lb.app-lb,
    azurerm_lb_probe.health-probe
  ]
}