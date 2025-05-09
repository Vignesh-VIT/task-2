locals {
  common_tags = {
    environment = "dev"
    owner       = "gsv1cob@bosch.com"
    department  = "ADA"
    project     = "two-tier-application"
  }
}

module "resource_group" {
  source   = "./modules/rg"
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

module "network" {
  source              = "./modules/network"
  name                = var.vnet_name
  location            = module.resource_group.resource_group_location
  resource_group_name = module.resource_group.resource_group_name
  address_space       = var.address_space
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  tags                = local.common_tags
}

module "nsg_public" {
  source              = "./modules/nsg"
  name                = "${var.environment}-public-nsg"
  location            = module.resource_group.resource_group_location
  resource_group_name = module.resource_group.resource_group_name
  tags                = local.common_tags
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
      description                  = "Allow SSH from specified sources"
    }
  ]
}


module "nsg_private" {
  source              = "./modules/nsg"
  name                = "${var.environment}-private-nsg"
  location            = module.resource_group.resource_group_location
  resource_group_name = module.resource_group.resource_group_name
  tags                = local.common_tags
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
      description                  = "Allow SSH from public subnet"
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
  name                = "${var.environment}-server1-public-ip"
  location            = module.resource_group.resource_group_location
  resource_group_name = module.resource_group.resource_group_name
  tags                = local.common_tags
}

module "nic_server1" {
  source                    = "./modules/nic"
  name                      = "${var.environment}-server1-nic"
  location                  = module.resource_group.resource_group_location
  resource_group_name       = module.resource_group.resource_group_name
  subnet_id                 = module.network.public_subnet_id
  public_ip_id              = module.public_ip.public_ip_id
  network_security_group_id = module.nsg_public.network_security_group_id
  tags                      = local.common_tags
}

module "nic_server2" {
  source                    = "./modules/nic"
  name                      = "${var.environment}-server2-nic"
  location                  = module.resource_group.resource_group_location
  resource_group_name       = module.resource_group.resource_group_name
  subnet_id                 = module.network.private_subnet_id
  network_security_group_id = module.nsg_private.network_security_group_id
  tags                      = local.common_tags
}

module "vm_server1" {
  source              = "./modules/vm"
  name                = "${var.environment}-server1"
  location            = module.resource_group.resource_group_location
  resource_group_name = module.resource_group.resource_group_name
  nic_id              = module.nic_server1.nic_id
  admin_username      = var.admin_username
  public_key_path     = var.public_key_path
  vm_size             = var.public_vm_size
  tags                = merge(local.common_tags, { Role = "Public Server" })
}

module "vm_server2" {
  source              = "./modules/vm"
  name                = "${var.environment}-server2"
  location            = module.resource_group.resource_group_location
  resource_group_name = module.resource_group.resource_group_name
  nic_id              = module.nic_server2.nic_id
  admin_username      = var.admin_username
  public_key_path     = var.public_key_path
  vm_size             = var.private_vm_size
  tags                = merge(local.common_tags, { Role = "Private Server" })
}