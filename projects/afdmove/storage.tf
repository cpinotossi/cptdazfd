# Role assignment for service principal at resource group level
resource "azurerm_role_assignment" "sp_blob_contributor" {
  scope                = azurerm_resource_group.cptdazafdmove.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.service_principal_object_id
}

# Storage Account
resource "azurerm_storage_account" "cptdazafdmove" {
  name                     = var.prefix
  resource_group_name      = azurerm_resource_group.cptdazafdmove.name
  location                 = azurerm_resource_group.cptdazafdmove.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  public_network_access_enabled     = true
  shared_access_key_enabled         = false
  default_to_oauth_authentication   = true
  allow_nested_items_to_be_public   = false

  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    ip_rules                   = [
      data.http.my_ip.response_body,
      # Azure Front Door Backend IPs for West Europe (filtered to /0-/30 prefixes only)
      "4.153.250.0/29","4.189.206.24/30","4.189.206.32/28","4.189.210.0/29","4.198.222.0/29","4.213.81.64/29","4.232.98.120/29","13.73.248.16/29","20.17.126.64/29","20.21.37.40/29","20.36.120.104/29","20.37.64.104/29","20.37.156.120/29","20.37.195.0/29","20.37.224.104/29","20.38.84.72/29","20.38.136.104/29","20.39.11.8/29","20.41.4.88/29","20.41.64.120/29","20.41.192.104/29","20.42.4.120/29","20.42.129.152/29","20.42.224.104/29","20.43.41.136/29","20.43.65.128/29","20.43.130.80/29","20.45.112.104/29","20.45.192.104/29","20.59.103.64/29","20.72.18.248/29","20.79.107.152/29","20.88.157.176/29","20.90.132.152/29","20.113.254.88/29","20.115.247.64/29","20.118.195.128/29","20.119.155.128/29","20.150.160.96/29","20.189.106.112/29","20.192.161.104/29","20.192.225.48/29","20.210.70.64/30","20.215.4.240/29","20.217.44.240/29","40.67.48.104/29","40.74.30.72/29","40.80.56.104/29","40.80.168.104/29","40.80.184.120/29","40.82.248.248/29","40.89.16.104/29","48.192.88.228/30","48.192.88.232/29","48.192.136.20/30","48.194.5.188/30","48.194.6.0/29","51.12.41.8/29","51.12.193.8/29","51.53.30.144/29","51.104.25.128/29","51.105.80.104/29","51.105.88.104/29","51.107.48.104/29","51.107.144.104/29","51.120.40.104/29","51.120.224.104/29","51.137.160.112/29","52.136.48.104/29","52.140.104.104/29","52.150.136.120/29","52.159.71.160/29","52.228.80.120/29","68.210.172.176/29","68.221.93.128/29","69.15.0.0/16","102.133.56.88/29","102.133.216.88/29","135.222.195.0/29","147.243.0.0/16","158.23.108.56/29","172.179.226.0/29","172.199.23.76/30","172.199.23.80/29","172.199.232.0/29","172.204.165.112/29","172.207.69.80/30","191.233.9.120/29","191.235.225.128/29"
    ]
  }

  depends_on = [azurerm_role_assignment.sp_blob_contributor]
}

# Static Website Configuration
resource "azurerm_storage_account_static_website" "cptdazafdmove" {
  storage_account_id = azurerm_storage_account.cptdazafdmove.id
  index_document     = "index.html"
  error_404_document = "error.html"
}


