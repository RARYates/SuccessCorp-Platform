terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# Set ARM_SUBSCRIPTION_ID in your environment (or run `az login` and export it).
provider "azurerm" {
  features {}
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "eastus"
}

resource "azurerm_resource_group" "rg" {
  name     = "SuccessCorp-Env-rg"
  location = var.location
}

resource "azurerm_log_analytics_workspace" "logs" {
  name                = "SuccessCorp-logs"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_app_environment" "env" {
  name                       = "SuccessCorp-env"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id
}