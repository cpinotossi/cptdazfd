# Azure Front Door Profile (Premium for Private Link)
resource "azurerm_cdn_frontdoor_profile" "cptdazafdmove" {
  name                = var.prefix
  resource_group_name = azurerm_resource_group.cptdazafdmove.name
  sku_name            = "Premium_AzureFrontDoor"

  # identity {
  #   type = "SystemAssigned"
  # }
}

# Front Door Endpoint
resource "azurerm_cdn_frontdoor_endpoint" "cptdazafdmove" {
  name                     = var.prefix
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.cptdazafdmove.id
}

# Front Door Origin Group
resource "azurerm_cdn_frontdoor_origin_group" "cptdazafdmove" {
  name                     = var.prefix
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.cptdazafdmove.id

  load_balancing {
    additional_latency_in_milliseconds = 50
    sample_size                        = 4
    successful_samples_required        = 3
  }
}

# Front Door Origin (Storage Account Static Website)
# Note: Private Link not supported with static website endpoint
# The private endpoint connection exists but is not used by AFD
resource "azurerm_cdn_frontdoor_origin" "cptdazafdmove" {
  name                          = var.prefix
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.cptdazafdmove.id

  enabled                        = true
  host_name                      = azurerm_storage_account.cptdazafdmove.primary_web_host
  origin_host_header             = azurerm_storage_account.cptdazafdmove.primary_web_host
  priority                       = 1
  weight                         = 1000
  certificate_name_check_enabled = true
}

# Front Door Route - Main route
resource "azurerm_cdn_frontdoor_route" "cptdazafdmove" {
  name                          = var.prefix
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.cptdazafdmove.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.cptdazafdmove.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.cptdazafdmove.id]
  cdn_frontdoor_rule_set_ids    = [azurerm_cdn_frontdoor_rule_set.cptdazafdmove.id]

  enabled                = true
  forwarding_protocol    = "HttpsOnly"
  https_redirect_enabled = true
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]

  cache {
    query_string_caching_behavior = "IgnoreQueryString"
    compression_enabled           = false
    content_types_to_compress     = []
  }

  link_to_default_domain = true

  lifecycle {
    create_before_destroy = true
  }
}

# Front Door Rule Set for No-Cache Headers
resource "azurerm_cdn_frontdoor_rule_set" "cptdazafdmove" {
  name                     = var.prefix
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.cptdazafdmove.id
}

# Front Door rules removed - managed via portal
