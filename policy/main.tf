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


# Policy Definition audit tag for SGR mode:all



resource "azurerm_policy_definition" "audit_mandatory_tags" {
  name         = "audit-mandatory-tags"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Audit for mandatory tags and values"
  description  = "Audits resources to ensure they have required tags and valid values for specific tags, excluding system-level resources."

  metadata = jsonencode({
    version  = "1.0.0"
    category = "Tags"
    source   = "https://github.com/Azure/Enterprise-Scale/"
    alzCloudEnvironments = [
      "AzureCloud",
      "AzureChinaCloud",
      "AzureUSGovernment"
    ]
  })


  parameters = jsonencode({
    effect = {
      type = "String"
      metadata = {
        displayName = "Effect"
        description = "Enable or disable the execution of the policy"
      }
      allowedValues = ["Audit", "Deny", "Disabled"]
      defaultValue  = "Audit"
    }
  })



  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field = "type"
          notIn = [
            "Microsoft.Security/policies",
            "Microsoft.Authorization/roleAssignments",
            "Microsoft.PolicyInsights/policyStates",
            "Microsoft.Insights/diagnosticSettings",
            "Microsoft.Advisor/recommendations",
            "Microsoft.Storage/storageAccounts/blobServices",
            "Microsoft.Storage/storageAccounts/fileServices",
            "Microsoft.Storage/storageAccounts/tableServices",
            "Microsoft.Storage/storageAccounts/queueServices"
          ]
        },
        {
          anyOf = [
            # Missing mandatory tags
            {
              field  = "tags['costcenter']"
              exists = false
            },
            {
              field  = "tags['Project']"
              exists = false
            },
            {
              field  = "tags['BusinessRequest']"
              exists = false
            },
            {
              field  = "tags['BusinessOwner']"
              exists = false
            },
            {
              field  = "tags['Environment']"
              exists = false
            },
            {
              field  = "tags['CompanyCode']"
              exists = false
            },
            {
              field  = "tags['Scm']"
              exists = false
            },
            {
              field  = "tags['DataClassification']"
              exists = false
            },
            {
              field  = "tags['BusinessCriticality']"
              exists = false
            },
            # Invalid values
            {
              field = "tags['Environment']"
              notIn = ["Prod", "Stg", "Dev"]
            },
            {
              field = "tags['DataClassification']"
              notIn = ["public", "internal", "confidential"]
            },
            {
              field = "tags['BusinessCriticality']"
              notIn = ["non-essential", "essential", "critical"]
            }
          ]
        }
      ]
    }
    then = {
      effect = "[parameters('effect')]"
    }
  })
}




# Policy Definition audit tag for SGR mode:indexed
resource "azurerm_policy_definition" "audit_mandatory_tags-indexed" {
  name         = "audit-mandatory-tags-mode-Indexed"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Audit for mandatory tags on resources indexed mode"
  description  = "Audits resources to ensure they have required tags based on tag array. Does not apply to resource groups."

  metadata = jsonencode({
    version  = "1.0.0"
    category = "Tags"
    source   = "https://github.com/Azure/Enterprise-Scale/"
    alzCloudEnvironments = [
      "AzureCloud",
      "AzureChinaCloud",
      "AzureUSGovernment"
    ]
  })

  parameters = jsonencode({
    effect = {
      type = "String"
      metadata = {
        displayName = "Effect"
        description = "Enable or disable the execution of the policy"
      }
      allowedValues = ["Audit", "Deny", "Disabled"]
      defaultValue  = "Audit"
    }
    mandatoryTags = {
      type = "Array"
      metadata = {
        displayName = "Array of mandatory tags indexed"
        description = "Array of mandatory tags that must be present on the resource."
      }
      defaultValue = var.mandatory_tags
    }
  })

  policy_rule = jsonencode({
    if = {
      not = {
        count = {
          value = "[parameters('mandatoryTags')]"
          name  = "tagcount"
          where = {
            field       = "tags"
            containsKey = "[current('tagcount')]"
          }
        }
        equals = "[length(parameters('mandatoryTags'))]"
      }
    }
    then = {
      effect = "[parameters('effect')]"
    }
  })
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
      effect = "audit"
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


##############################################

# Policy Assignments at subscription level - Audit mandatory tags - indexed


resource "azurerm_subscription_policy_assignment" "audit_mandatory_tags_assignment-indexed" {
  name                 = "audit-mandatory-tags-assignment-indexed"
  display_name         = "Audit Mandatory Tags Assignment"
  policy_definition_id = azurerm_policy_definition.audit_mandatory_tags-indexed.id
  subscription_id      = "/subscriptions/${var.subscription_id}"
  description          = "Audit all resources to ensure they have mandatory tags forSGR compliance"
  enforce              = true

  parameters = jsonencode({
    effect = {
      value = "Audit"
    }
    mandatoryTags = {
      value = var.mandatory_tags
    }
  })
}

# Policy Assignments at subscription level - Audit mandatory tags -all


resource "azurerm_subscription_policy_assignment" "audit_mandatory_tags_assignment" {
  name                 = "audit-mandatory-tags-assignment-all"
  display_name         = "Audit Mandatory Tags Assignment"
  policy_definition_id = azurerm_policy_definition.audit_mandatory_tags.id
  subscription_id      = "/subscriptions/${var.subscription_id}"
  description          = "Audit all resources to ensure they have mandatory tags forSGR compliance"
  enforce              = true

  parameters = jsonencode({
    effect = {
      value = "Audit"
    }
  })

  non_compliance_message {
    content = "Resource is missing required tags or contains invalid values for Environment, DataClassification, or BusinessCriticality."
  }
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