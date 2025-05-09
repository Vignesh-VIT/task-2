locals {
  common_tags = {
    owner      = "gsv1cob@bosch.com"
    department = "ADA"
    project    = "two-tier-application"
  }
  db_password = random_password.db_password.result
}

module "resource_group" {
  source   = "../modules/rg"
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

module "network" {
  source              = "../modules/network"
  name                = var.vnet_name
  location            = module.resource_group.resource_group_location
  resource_group_name = module.resource_group.resource_group_name
  address_space       = var.address_space
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  tags                = local.common_tags
}

module "nsg_public" {
  source              = "../modules/nsg"
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
  source              = "../modules/nsg"
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
  source              = "../modules/public_ip"
  name                = "${var.environment}-server1-public-ip"
  location            = module.resource_group.resource_group_location
  resource_group_name = module.resource_group.resource_group_name
  tags                = local.common_tags
}

module "nic_server1" {
  source                    = "../modules/nic"
  name                      = "${var.environment}-server1-nic"
  location                  = module.resource_group.resource_group_location
  resource_group_name       = module.resource_group.resource_group_name
  subnet_id                 = module.network.public_subnet_id
  public_ip_id              = module.public_ip.public_ip_id
  network_security_group_id = module.nsg_public.network_security_group_id
  tags                      = local.common_tags
}

module "nic_server2" {
  source                    = "../modules/nic"
  name                      = "${var.environment}-server2-nic"
  location                  = module.resource_group.resource_group_location
  resource_group_name       = module.resource_group.resource_group_name
  subnet_id                 = module.network.private_subnet_id
  network_security_group_id = module.nsg_private.network_security_group_id
  tags                      = local.common_tags
}

module "vm_server1" {
  source              = "../modules/vm"
  name                = "${var.environment}-server1"
  location            = module.resource_group.resource_group_location
  resource_group_name = module.resource_group.resource_group_name
  nic_id              = module.nic_server1.nic_id
  admin_username      = var.admin_username
  public_key_path     = var.public_key_path
  vm_size             = var.public_vm_size
  environment         = var.environment
  install_flask       = false
  tags                = merge(local.common_tags, { Role = "Public Server" })
}

module "vm_server2" {
  source              = "../modules/vm"
  name                = "${var.environment}-server2"
  location            = module.resource_group.resource_group_location
  resource_group_name = module.resource_group.resource_group_name
  nic_id              = module.nic_server2.nic_id
  admin_username      = var.admin_username
  public_key_path     = var.public_key_path
  vm_size             = var.private_vm_size
  environment         = var.environment
  install_flask       = false
  tags                = merge(local.common_tags, { Role = "Private Server" })
}

resource "random_password" "db_password" {
  length  = 16
  special = false
}

module "keyvault" {
  source               = "../modules/keyvault"
  name                 = "${var.environment}-keyvault-${random_id.keyvault_suffix.hex}"
  location             = module.resource_group.resource_group_location
  resource_group_name  = module.resource_group.resource_group_name
  vm_principal_id      = module.vm_server1.principal_id
  db_password          = local.db_password
  db_connection_string = "postgresql://${var.db_username}:${local.db_password}@${module.nic_server2.private_ip_address}:5432/${var.db_name}"
  tags                 = local.common_tags
  depends_on           = [module.vm_server1]
}

resource "azurerm_virtual_machine_extension" "flask_app" {
  name                 = "install-flask-app"
  virtual_machine_id   = module.vm_server1.vm_id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  settings = jsonencode({
    script = base64encode(templatefile("../${path.module}/scripts/install_flask.sh", {
      key_vault_uri = module.keyvault.key_vault_uri
    }))
  })

  depends_on = [module.keyvault]
}

resource "azurerm_virtual_machine_extension" "postgresql" {
  name                 = "install-postgresql"
  virtual_machine_id   = module.vm_server2.vm_id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  settings = jsonencode({
    script = base64encode(templatefile("../${path.module}/scripts/install_postgresql.sh", {
      db_password = local.db_password
      db_username = var.db_username
      db_name     = var.db_name
    }))
  })

  depends_on = [module.vm_server2]
}

resource "random_id" "keyvault_suffix" {
  byte_length = 4
}