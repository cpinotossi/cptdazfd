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
