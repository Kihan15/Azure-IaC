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

# Policy Definition denying resources without a specific tag "ITDamien123"
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
          field    = "tags['environment']"
          notIn    = ["prod", "stg", "dev"]
        }
      ]
    }
    then = {
      effect = "audit"
    }
  })
}


# Policy Definition - Modify environment tag to default value
resource "azurerm_policy_definition" "modify_environment_tag" {
  name         = "modify-invalid-environment-tag"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Modify invalid environment tag values"
  description  = "This policy modifies resources where the environment tag value is not prod, stg, or dev to a default value"

  metadata = jsonencode({
    category = "Tags"
    version  = "1.0.0"
  })

  parameters = jsonencode({
    defaultEnvironmentValue = {
      type = "String"
      metadata = {
        displayName = "Default Environment Value"
        description = "The default value to set when environment tag is invalid or missing"
      }
      allowedValues = ["prod", "stg", "dev"]
      defaultValue  = "dev"
    }
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
      effect = "modify"
      details = {
        roleDefinitionIds = [
          "/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
        ]
        operations = [
          {
            operation = "addOrReplace"
            field     = "tags['environment']"
            value     = "[parameters('defaultEnvironmentValue')]"
          }
        ]
      }
    }
  })
}





###############################################################################
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

# Policy Assignment at Subscription Level - Modify environment tag
resource "azurerm_subscription_policy_assignment" "modify_environment_tag" {
  name                 = "modify-environment-tag-assignment"
  subscription_id      = "/subscriptions/${var.subscription_id}"
  policy_definition_id = azurerm_policy_definition.modify_environment_tag.id
  display_name         = "Modify invalid environment tag values"
  description          = "Automatically fixes invalid environment tag values to default"
  enforce              = true

  identity {
    type = "SystemAssigned"
  }

  location = var.location

  parameters = jsonencode({
    defaultEnvironmentValue = {
      value = var.default_environment_value
    }
  })

  metadata = jsonencode({
    assignedBy = "Terraform"
  })

  non_compliance_message {
    content = "The 'environment' tag was invalid or missing and has been automatically corrected to '${var.default_environment_value}'."
  }
}

# Role Assignment - Grant Contributor role to the managed identity
resource "azurerm_role_assignment" "policy_remediation" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Contributor"
  principal_id         = azurerm_subscription_policy_assignment.modify_environment_tag.identity[0].principal_id

  depends_on = [
    azurerm_subscription_policy_assignment.modify_environment_tag
  ]
}
