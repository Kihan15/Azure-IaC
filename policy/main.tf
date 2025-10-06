terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}




# Policy Definition - Audit environment tag values
resource "azurerm_policy_definition" "audit_environment_tag" {
  name         = "audit-environment-tag-values"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Audit environment tag values"
  description  = "This policy audits resources where the environment tag value is not prod, stg, or dev"

  metadata = jsonencode({
    category = "Tags"
    version  = "1.0.0"
  })

  policy_rule = jsonencode({
    if = {
      anyOf = [
        {
          field  = "tags['environment']"
          exists = "false"
        },
        {
          field = "tags['environment']"
          notIn = ["prod", "stg", "dev"]
        }
      ]
    }
    then = {
      effect = "audit"
    }
  })
}



# Policy Assignment at Subscription Level - Audit environment tag
resource "azurerm_subscription_policy_assignment" "audit_environment_tag" {
  name                 = "audit-environment-tag-assignment"
  subscription_id      = "/subscriptions/${var.subscription_id}"
  policy_definition_id = azurerm_policy_definition.audit_environment_tag.id
  display_name         = "Audit environment tag values"
  description          = "Audits resources with invalid environment tag values (must be prod, stg, or dev)"
  enforce              = true

  metadata = jsonencode({
    assignedBy = "Terraform"
  })

  non_compliance_message {
    content = "The 'environment' tag must have one of the following values: prod, stg, dev. Current value is invalid or missing."
  }
}



