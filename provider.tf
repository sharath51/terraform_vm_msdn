# Terraform Block
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}
# Provider Block
provider "azurerm" {
  subscription_id = "181821eb-6bc1-41fa-bba6-5bfecf56c48f"
  features {

  }
}
