# Get current public IP
data "http" "my_ip" {
  url = "https://api.ipify.org"
}

# Get current client configuration
data "azurerm_client_config" "current" {
}
