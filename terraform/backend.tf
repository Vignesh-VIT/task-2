terraform {
  backend "azurerm" {
    # Backend configuration parameters will be provided via backend.tfvars during init
    # This allows us to use different state files for each environment
  }
}