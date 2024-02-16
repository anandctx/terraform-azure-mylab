terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.69.0"
    }
    tfe = {
      version = "~> 0.35"
    }
    azapi = {
      source = "azure/azapi"
    }
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = ">=0.2.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.42.0"
    }

  }
  required_version = ">=1.0.0"
}
