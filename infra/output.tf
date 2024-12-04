output "AZURE_LOCATION" {
  value = var.location
}

output "AZURE_TENANT_ID" {
  value = data.azurerm_client_config.current.tenant_id
}

output "AZURE_STORAGE_ACCOUNT" {
  value = azurerm_storage_account.st.name
}

output "AZURE_RESOURCE_GROUP" {
  value = azurerm_resource_group.rg.name
}

output "AZURE_SUBSCRIPTION_ID" {
  value = data.azurerm_client_config.current.subscription_id
}

output "AZURE_UAMI_ID" {
  value = azurerm_user_assigned_identity.mi.id
}

output "AZURE_UAMI_NAME" {
  value = azurerm_user_assigned_identity.mi.name
}
