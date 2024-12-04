
locals {
  storage_roles = ["Storage Blob Data Contributor", "Storage Queue Data Contributor"]
  rg_roles      = ["EventGrid EventSubscription Contributor"]
  # data layers with names for storage containers and external locations
  data_layers = [
    {
      name              = "appone_catalog"
      storage_container = "unitycatalog"
      external_location = "appone_unity_catalog"
    },
    {
      name              = "dropzone"
      storage_container = "dropzone"
      external_location = "appone_dropzone"
    },
    {
      name              = "checkpoints"
      storage_container = "checkpoints"
      external_location = "appone_checkpoints"
    }
  ]

  catalog_schemas = ["bronze", "silver", "gold"]
}


resource "random_pet" "adb_connector_name" {
  length    = 3
  separator = "-"
  prefix    = var.environment_name
}

resource "azurerm_user_assigned_identity" "mi" {
  name                = "uami-${azurerm_storage_account.st.name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_role_assignment" "mi_data_contributor" {
  count                = length(local.storage_roles)
  scope                = azurerm_storage_account.st.id
  role_definition_name = local.storage_roles[count.index]
  principal_id         = azurerm_user_assigned_identity.mi.principal_id
}

resource "azurerm_role_assignment" "mi_rg_contributor" {
  count                = length(local.rg_roles)
  scope                = azurerm_resource_group.rg.id
  role_definition_name = local.rg_roles[count.index]
  principal_id         = azurerm_user_assigned_identity.mi.principal_id
}


resource "azurerm_databricks_access_connector" "adb_connector" {
  name                = random_pet.adb_connector_name.id
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.mi.id]
  }

  tags = { env-name : var.environment_name }
}

resource "databricks_storage_credential" "external_mi" {
  name = "mi_credential"
  azure_managed_identity {
    access_connector_id = azurerm_databricks_access_connector.adb_connector.id
    managed_identity_id = azurerm_user_assigned_identity.mi.id
  }
  comment = "Managed identity credential managed by TF"

}

resource "azurerm_storage_container" "containers" {
  count                 = length(local.data_layers)
  name                  = local.data_layers[count.index].storage_container
  storage_account_id    = azurerm_storage_account.st.id
  container_access_type = "private"

}
# Create external locations linked to the storage containers
resource "databricks_external_location" "catalog" {
  count           = length(local.data_layers)
  name            = local.data_layers[count.index].external_location
  url             = format("abfss://%s@%s.dfs.core.windows.net/", local.data_layers[count.index].storage_container, azurerm_storage_account.st.name)
  credential_name = databricks_storage_credential.external_mi.id
  #   owner           = databricks_storage_credential.external_mi.name
  comment = "External location for App One ${local.data_layers[count.index].name}"

  depends_on    = [azurerm_role_assignment.mi_data_contributor, azurerm_role_assignment.mi_rg_contributor]
  force_destroy = true
}

resource "databricks_catalog" "catalog" {
  name           = local.data_layers[0].name
  comment        = "Catalog for App One ${local.data_layers[0].name}"
  storage_root   = format("abfss://%s@%s.dfs.core.windows.net/", local.data_layers[0].storage_container, azurerm_storage_account.st.name)
  isolation_mode = "OPEN"

  depends_on = [azurerm_storage_account.st,
  databricks_external_location.catalog]

}

resource "databricks_schema" "schemas" {
  count        = length(local.catalog_schemas)
  catalog_name = databricks_catalog.catalog.id
  name         = local.catalog_schemas[count.index]
  comment      = "Schema for App One ${local.catalog_schemas[count.index]}"

}

data "databricks_cluster" "cluster" {
  count        = var.adb_cluster_name != "" ? 1 : 0
  cluster_name = var.adb_cluster_name
}

resource "databricks_sql_table" "event_table" {
  name               = "events"
  catalog_name       = databricks_catalog.catalog.name
  schema_name        = local.catalog_schemas[0]
  table_type         = "MANAGED"
  data_source_format = "DELTA"
  storage_location   = ""

  cluster_id = var.adb_cluster_name != "" ? data.databricks_cluster.cluster[0].id : null

  column {
    name = "id"
    type = "int"
  }
  column {
    name    = "name"
    type    = "string"
    comment = "name of thing"
  }
  comment = "this table is managed by terraform"

  depends_on = [databricks_schema.schemas, databricks_external_location.catalog]
}
