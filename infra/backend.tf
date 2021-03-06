terraform {
  #required_version = "~> 0.14"
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"      
    }
  }
  backend "azurerm" {
    # Storage account
    resource_group_name  = "kubeflowdevops-infra-rg"
    storage_account_name = "kubeflowdevopstfsa"
    container_name       = "tfstate"
    key                  = "infra.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  # version = "2.40.0"
  # Specify Azure subscription and tenant
  subscription_id = local.subscription_id
  tenant_id       = local.tenant_id
  # Specify Azure service principal credentials used by terraform (if used)
  # client_id     = var.service_principal_client_id
  # client_secret = var.service_principal_client_secret
}
