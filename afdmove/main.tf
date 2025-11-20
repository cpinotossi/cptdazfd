# Resource Group
resource "azurerm_resource_group" "cptdazafdmove" {
  name     = var.prefix
  location = var.location
}