locals {
  resource_group_name = "rg-two-tier-architecture"
  location            = "westeurope"
  vnet_name           = "two-tier-vnet"
  address_space       = ["10.0.0.0/16"]
  public_subnet_cidr  = ["10.0.1.0/24"]
  private_subnet_cidr = ["10.0.2.0/24"]
  tags = {
    environment = "dev"
    owner       = "gsv1cob@bosch.com"
    department  = "ADA"
    project     = "two-tier-application"
  }
  admin_username = "azureuser"

}

resource "azurerm_resource_group" "rg" {
  name     = local.resource_group_name
  location = local.location
}

module "network" {
  source              = "./modules/network"
  name                = local.vnet_name
  location            = local.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = local.address_space
  public_subnet_cidr  = local.public_subnet_cidr
  private_subnet_cidr = local.private_subnet_cidr
  tags                = local.tags
}

module "nsg_public" {
  source              = "./modules/nsg"
  name                = "public-nsg"
  location            = local.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
  security_rules = [
    {
      name                         = "Allow-SSH"
      priority                     = 1001
      direction                    = "Inbound"
      access                       = "Allow"
      protocol                     = "Tcp"
      source_port_ranges           = ["0-65535"]
      destination_port_ranges      = ["22"]
      source_address_prefixes      = ["0.0.0.0/0"]
      destination_address_prefixes = ["10.0.1.0/24"]
      description                  = "Allow SSH from internet"
    }
  ]
}

module "nsg_private" {
  source              = "./modules/nsg"
  name                = "private-nsg"
  location            = local.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
  security_rules = [
    {
      name                         = "Allow-SSH-from-Server1"
      priority                     = 1001
      direction                    = "Inbound"
      access                       = "Allow"
      protocol                     = "Tcp"
      source_port_ranges           = ["0-65535"]
      destination_port_ranges      = ["22"]
      source_address_prefixes      = ["10.0.1.0/24"]
      destination_address_prefixes = ["10.0.2.0/24"]
      description                  = "Allow SSH from server1"
    },
    {
      name                         = "deny-SSH-from-other"
      priority                     = 1002
      direction                    = "Inbound"
      access                       = "Deny"
      protocol                     = "Tcp"
      source_port_ranges           = ["0-65535"]
      destination_port_ranges      = ["22"]
      source_address_prefixes      = ["0.0.0.0/0"]
      destination_address_prefixes = ["10.0.2.0/24"]
      description                  = "Deny all other inbound SSH traffic"
    }
  ]
}


module "public_ip" {
  source              = "./modules/public_ip"
  name                = "server1-public-ip"
  location            = local.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
}

module "nic_server1" {
  source                    = "./modules/nic"
  name                      = "server1-nic"
  location                  = local.location
  resource_group_name       = azurerm_resource_group.rg.name
  subnet_id                 = module.network.public_subnet_id
  public_ip_id              = module.public_ip.public_ip_id
  network_security_group_id = module.nsg_public.network_security_group_id
  tags                      = local.tags
}

module "nic_server2" {
  source                    = "./modules/nic"
  name                      = "server2-nic"
  location                  = local.location
  resource_group_name       = azurerm_resource_group.rg.name
  subnet_id                 = module.network.private_subnet_id
  network_security_group_id = module.nsg_private.network_security_group_id
  tags                      = local.tags
}

module "vm_server1" {
  source              = "./modules/vm"
  name                = "server1"
  location            = local.location
  resource_group_name = azurerm_resource_group.rg.name
  nic_id              = module.nic_server1.nic_id
  admin_username      = local.admin_username
  public_key_path     = var.public_key_path
  tags                = merge(local.tags, { Role = "Public Server" })
}

module "vm_server2" {
  source              = "./modules/vm"
  name                = "server2"
  location            = local.location
  resource_group_name = azurerm_resource_group.rg.name
  nic_id              = module.nic_server2.nic_id
  admin_username      = local.admin_username
  public_key_path     = var.public_key_path
  tags                = merge(local.tags, { Role = "Private Server" })
}