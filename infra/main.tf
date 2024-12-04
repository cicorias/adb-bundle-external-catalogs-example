locals {
  tags           = { env-name : var.environment_name }
  sha            = base64encode(sha256("${var.environment_name}${var.location}${data.azurerm_client_config.current.subscription_id}"))
  resource_token = substr(replace(lower(local.sha), "[^A-Za-z0-9_]", ""), 0, 13)
}

resource "azurecaf_name" "rg_name" {
  name          = var.environment_name
  resource_type = "azurerm_resource_group"
  random_length = 0
  clean_input   = true
}

resource "azurecaf_name" "st_name" {
  name          = var.environment_name
  resource_type = "azurerm_storage_account"
  random_length = 15
  clean_input   = true
}

# Deploy resource group
resource "azurerm_resource_group" "rg" {
  name     = azurecaf_name.rg_name.result
  location = var.location
  tags     = { env-name : var.environment_name }
}

# Deploy storage account
resource "azurerm_storage_account" "st" {
  name                       = azurecaf_name.st_name.result
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  account_tier               = "Standard"
  account_replication_type   = "LRS"
  account_kind               = "StorageV2"
  https_traffic_only_enabled = true
  shared_access_key_enabled  = true
  is_hns_enabled             = true
  blob_properties {
    delete_retention_policy {
      days                     = 1
      permanent_delete_enabled = true
    }
  }

  tags = { env-name : var.environment_name }
}
