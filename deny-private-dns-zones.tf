resource "random_id" "deny_private_dns_zones_id" {
  count = var.deny_prive_dns_zone_creation ? 1 : 0
  byte_length = 16
}

resource "azurerm_management_group_policy_assignment" "deny_private_dns_zones_assignment" {
  count = var.deny_prive_dns_zone_creation ? 1 : 0
  name                 = random_id.deny_private_dns_zones_id[0].id
  management_group_id  = data.azurerm_management_group.root.id
  policy_definition_id = azurerm_policy_definition.deny_policy[0].id
  display_name         = "Deny Private DNS Zones outside of the DNS Resource Group"
  non_compliance_message {
    content = "Private DNS Zones are not allowed outside of the DNS Resource Group"
  }
  enforce    = true
  not_scopes = [azurerm_resource_group.resource_group_dns.id]
}

resource "azurerm_policy_definition" "deny_policy" {
  count = var.deny_prive_dns_zone_creation ? 1 : 0
  name         = "DenyPrivateDNSZones"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Deny the creation of private DNS Zones"
  description  = "This policy denies the creation of a private DNS in the current scope, used in combination with policies that create centralized private DNS in connectivity subscription"

  management_group_id = data.azurerm_management_group.root.id

  metadata = <<METADATA
    {
    "category": "Network"
    }

METADATA

  policy_rule = <<POLICY_RULE
{
      "if": {
        "field": "type",
        "equals": "Microsoft.Network/privateDnsZones"
      },
      "then": {
        "effect": "[parameters('effect')]"
      }
    }
POLICY_RULE

  parameters = <<PARAMETERS
{
      "effect": {
        "type": "string",
        "allowedValues": [
          "Audit",
          "Deny",
          "Disabled"
        ],
        "defaultValue": "Deny",
        "metadata": {
          "displayName": "Effect",
          "description": "Enable or disable the execution of the policy"
        }
      }
    }
PARAMETERS
}
