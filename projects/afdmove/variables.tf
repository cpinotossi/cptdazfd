variable "subscription_id" {
  type      = string
  sensitive = true
}

variable "client_id" {
  type      = string
  sensitive = true
}

variable "client_secret" {
  type      = string
  sensitive = true
}

variable "tenant_id" {
  type      = string
  sensitive = true
}

variable "service_principal_object_id" {
  type      = string
  sensitive = true
}

variable "prefix" {
  type    = string
  default = "cptdazafdmove"
}

variable "location" {
  type    = string
  default = "westeurope"
}

variable "afd_sku" {
  description = "Azure Front Door SKU: Standard_AzureFrontDoor or Premium_AzureFrontDoor. Note: WAF requires Premium."
  type        = string
  default     = "Standard_AzureFrontDoor"

  validation {
    condition     = contains(["Standard_AzureFrontDoor", "Premium_AzureFrontDoor"], var.afd_sku)
    error_message = "The afd_sku must be either 'Standard_AzureFrontDoor' or 'Premium_AzureFrontDoor'."
  }
}

variable "waf_enabled" {
  description = "Enable WAF (Web Application Firewall) policy. Note: Enabling WAF automatically upgrades to Premium SKU."
  type        = bool
  default     = true
}
