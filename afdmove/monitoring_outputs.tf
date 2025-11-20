output "log_analytics_workspace_id" {
  value       = azurerm_log_analytics_workspace.cptdazafdmove.id
  description = "Log Analytics workspace ID for monitoring"
}

output "log_analytics_workspace_name" {
  value       = azurerm_log_analytics_workspace.cptdazafdmove.name
  description = "Log Analytics workspace name"
}
