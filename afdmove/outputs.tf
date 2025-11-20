output "frontdoor_endpoint_url" {
  value = "https://${azurerm_cdn_frontdoor_endpoint.cptdazafdmove.host_name}/walk.txt"
  description = "Front Door URL to access walk.txt"
}

output "frontdoor_endpoint_host" {
  value = azurerm_cdn_frontdoor_endpoint.cptdazafdmove.host_name
  description = "Front Door endpoint hostname"
}

output "storage_account_name" {
  value       = azurerm_storage_account.cptdazafdmove.name
  description = "Storage account name"
}

output "frontdoor_profile_name" {
  value       = azurerm_cdn_frontdoor_profile.cptdazafdmove.name
  description = "Front Door profile name"
}

output "resource_group_name" {
  value       = azurerm_resource_group.cptdazafdmove.name
  description = "Resource group name"
}

output "my_public_ip" {
  value       = local.my_public_ip
  description = "Your current public IP address"
}

output "storage_account_id" {
  value = azurerm_storage_account.cptdazafdmove.id
}

output "static_website_url" {
  value       = azurerm_storage_account.cptdazafdmove.primary_web_endpoint
  description = "Static website primary endpoint"
}

output "static_website_host" {
  value       = azurerm_storage_account.cptdazafdmove.primary_web_host
  description = "Static website hostname (without https://)"
}
