resource "azurerm_resource_group" "k8hway" {
  name     = "${var.prefix}-RG"
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "k8hway" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.k8hway.location
  resource_group_name = azurerm_resource_group.k8hway.name
  tags                = var.tags
}

resource "azurerm_subnet" "master" {
  name                 = "master"
  resource_group_name  = azurerm_resource_group.k8hway.name
  virtual_network_name = azurerm_virtual_network.k8hway.name
  address_prefix       = "10.0.0.0/24"
}

resource "azurerm_subnet" "worker" {
  name                 = "worker"
  resource_group_name  = azurerm_resource_group.k8hway.name
  virtual_network_name = azurerm_virtual_network.k8hway.name
  address_prefix       = "10.0.1.0/24"
}

# NIC and IPs for Master Node
resource "azurerm_public_ip" "master" {
  count               = var.master_node_count
  name                = "${var.prefix}-${count.index}-master-pip"
  resource_group_name = azurerm_resource_group.k8hway.name
  location            = azurerm_resource_group.k8hway.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

output "public_ip" {
  value = [azurerm_public_ip.master.*.ip_address]
}

resource "azurerm_network_interface" "master" {
  count               = var.master_node_count
  name                = "${var.prefix}-nic-master-${count.index}"
  location            = azurerm_resource_group.k8hway.location
  resource_group_name = azurerm_resource_group.k8hway.name

  ip_configuration {
    name                          = "configuration-${count.index}"
    subnet_id                     = azurerm_subnet.master.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = element(azurerm_public_ip.master.*.id, count.index)
  }
}

# NIC and IPs for Worker Nodes

// resource "azurerm_public_ip" "worker" {
//   count               = "${var.worker_node_count}"
//   name                = "${var.prefix}-${count.index}-worker-pip"
//   resource_group_name = "${azurerm_resource_group.k8hway.name}"
//   location            = "${azurerm_resource_group.k8hway.location}"
//   allocation_method   = "Dynamic"
//   sku                 = "Basic"
//   tags                = "${var.tags}"
// }

resource "azurerm_network_interface" "worker" {
  count               = var.worker_node_count
  name                = "${var.prefix}-nic-worker-${count.index}"
  location            = azurerm_resource_group.k8hway.location
  resource_group_name = azurerm_resource_group.k8hway.name

  ip_configuration {
    name                          = "configuration-${count.index}"
    subnet_id                     = azurerm_subnet.worker.id
    private_ip_address_allocation = "Dynamic"
  }
}

