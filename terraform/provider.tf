terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.39.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.57.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "1.6.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
  features {}
}

provider "azuread" {
  # Configuration options
}

provider "azapi" {
  # Configuration options
}
