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

# Policy Definition
resource "azurerm_policy_definition" "deny_missing_tag" {
  name         = "deny-missing-${var.tag_name}-tag"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Deny resources without ${var.tag_name} tag"
  description  = "This policy denies the creation of resources that don't have a ${var.tag_name} tag"

  metadata = jsonencode({
    category = "Tags"
    version  = "1.0.0"
  })

  policy_rule = jsonencode({
    if = {
      field  = "tags['${var.tag_name}']"
      exists = "false"
    }
    then = {
      effect = "deny"
    }
  })
}

# Policy Assignment at Subscription Level
resource "azurerm_subscription_policy_assignment" "deny_missing_tag" {
  name                 = "deny-missing-${var.tag_name}-assignment"
  subscription_id      = "/subscriptions/${var.subscription_id}"
  policy_definition_id = azurerm_policy_definition.deny_missing_tag.id
  display_name         = "Deny resources without ${var.tag_name} tag"
  description          = "Enforces ${var.tag_name} tag on all resources in the subscription"
  enforce              = true

  non_compliance_message {
    content = "Resources must have a '${var.tag_name}' tag. Please add the ${var.tag_name} tag before creating this resource."
  }
}