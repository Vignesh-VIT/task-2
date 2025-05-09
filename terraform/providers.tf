terraform {
  required_version = "1.7.4"

  backend "azurerm" {
    resource_group_name  = "tfstatestorage"
    storage_account_name = "tfstatestorageserver"
    container_name       = "terraform-state"
    key                  = "two-server-architecture.tfstate"
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.117.0"
    }
  }
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
}

