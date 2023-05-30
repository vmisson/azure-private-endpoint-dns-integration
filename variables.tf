variable "location" {
  default = "westeurope"
}

variable "resource_group_dns_name" {
  default = "private-dns-zones-rg"
}

variable "user_assigned_identity_name" {
  default = "dns-remediation-managed-identity"
}