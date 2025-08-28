variable "subscription_id" {
  description = "The ID of the Azure subscription where the resources will be created."
  type        = string
}

variable "location" {
  description = "The Azure region where the resources will be created."
  type = string
  default = "westeurope"
}

variable "resource_group_dns_name" {
  description = "Name of the resource group"
  type = string
  default = "rg-dns-priv-001"
}

variable "user_assigned_identity_name" {
  type = string
  default = "mi-dns-remediation"
}

variable "deny_prive_dns_zone_creation" {
  type = bool
  default = false
}