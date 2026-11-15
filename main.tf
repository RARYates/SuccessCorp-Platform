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

locals {
  platform_tags = {
    environment = "demo"
    workspace   = terraform.workspace
    layer       = "platform"
    managed_by  = "terraform"
  }
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

  # Pricing and retention
  sku               = "PerGB2018" # pay-as-you-go per GB ingested
  retention_in_days = 30          # 30–730 days
  daily_quota_gb    = -1          # -1 = no daily ingestion cap

  # Access model
  allow_resource_only_permissions = true  # users can read logs for resources they have access to
  cmk_for_query_forced            = false # customer-managed key not required for saved queries

  # Network access (set to false when using Azure Monitor Private Link Scope)
  internet_ingestion_enabled = true
  internet_query_enabled     = true

  # Data lifecycle
  immediate_data_purge_on_30_days_enabled = false

  identity {
    type = "SystemAssigned"
  }

  # Not set (need other resources or a different SKU):
  # reservation_capacity_in_gb_per_day = 100   # only with sku = "CapacityReservation"
  # data_collection_rule_id            = ...   # needs an azurerm_monitor_data_collection_rule

  tags = local.platform_tags
}

resource "azurerm_container_app_environment" "env" {
  name                = "SuccessCorp-env"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  # Observability: app logs flow to the platform workspace
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id

  # Security
  mutual_tls_enabled = false # mTLS between apps in the environment

  # Compute: an explicit Consumption workload profile (serverless, scale to zero)
  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }

  # Not set (need a VNet / other resources):
  # infrastructure_subnet_id           = azurerm_subnet.aca.id  # /23 or larger, delegated subnet
  # internal_load_balancer_enabled     = true                   # needs infrastructure_subnet_id
  # zone_redundancy_enabled            = true                   # needs infrastructure_subnet_id
  # infrastructure_resource_group_name = "ME_SuccessCorp-env"   # needs subnet + workload profiles
  # dapr_application_insights_connection_string = azurerm_application_insights.ai.connection_string

  tags = local.platform_tags
}
