# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "cptdazafdmove" {
  name                = var.prefix
  resource_group_name = azurerm_resource_group.cptdazafdmove.name
  location            = azurerm_resource_group.cptdazafdmove.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Diagnostic Settings for Storage Account - Blob Service
resource "azurerm_monitor_diagnostic_setting" "storage_blob" {
  name                       = "${var.prefix}-blob-diagnostics"
  target_resource_id         = "${azurerm_storage_account.cptdazafdmove.id}/blobServices/default"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.cptdazafdmove.id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }

  enabled_metric {
    category = "Transaction"
  }

  enabled_metric {
    category = "Capacity"
  }
}

# Diagnostic Settings for Azure Front Door
resource "azurerm_monitor_diagnostic_setting" "frontdoor" {
  name                       = "${var.prefix}-afd-diagnostics"
  target_resource_id         = azurerm_cdn_frontdoor_profile.cptdazafdmove.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.cptdazafdmove.id

  enabled_log {
    category = "FrontDoorAccessLog"
  }

  enabled_log {
    category = "FrontDoorHealthProbeLog"
  }

  enabled_log {
    category = "FrontDoorWebApplicationFirewallLog"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
