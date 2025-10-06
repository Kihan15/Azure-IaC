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



#Indivuidual polify definition and group it in policy initiative for better management - Then assigbnement



############################################################
# Policy: Require tag CostCenter
############################################################
resource "azurerm_policy_definition" "tag_costcenter_required" {
  name         = "tag-costcenter-required"
  display_name = "Require tag: CostCenter"
  description  = "Audits resources missing the 'CostCenter' tag."
  policy_type  = "Custom"
  mode         = "Indexed"
  metadata     = jsonencode({ category = "Tags" })

  parameters = jsonencode({
    effect = {
      type          = "String"
      metadata      = { displayName = "Effect" }
      allowedValues = ["Audit", "Deny", "Disabled"]
      defaultValue  = "Audit"
    }
  })

  policy_rule = jsonencode({
    if = {
      field  = "tags['CostCenter']"
      exists = false
    }
    then = {
      effect = "[parameters('effect')]"
    }
  })
}

############################################################
# Policy: Require tag Project
############################################################
resource "azurerm_policy_definition" "tag_project_required" {
  name         = "tag-project-required"
  display_name = "Require tag: Project"
  description  = "Audits resources missing the 'Project' tag."
  policy_type  = "Custom"
  mode         = "Indexed"
  metadata     = jsonencode({ category = "Tags" })

  parameters = jsonencode({
    effect = {
      type          = "String"
      metadata      = { displayName = "Effect" }
      allowedValues = ["Audit", "Deny", "Disabled"]
      defaultValue  = "Audit"
    }
  })

  policy_rule = jsonencode({
    if = {
      field  = "tags['Project']"
      exists = false
    }
    then = {
      effect = "[parameters('effect')]"
    }
  })
}

############################################################
# Policy: Require tag BusinessRequest
############################################################
resource "azurerm_policy_definition" "tag_businessrequest_required" {
  name         = "tag-businessrequest-required"
  display_name = "Require tag: BusinessRequest"
  description  = "Audits resources missing the 'BusinessRequest' tag."
  policy_type  = "Custom"
  mode         = "Indexed"
  metadata     = jsonencode({ category = "Tags" })

  parameters = jsonencode({
    effect = {
      type          = "String"
      metadata      = { displayName = "Effect" }
      allowedValues = ["Audit", "Deny", "Disabled"]
      defaultValue  = "Audit"
    }
  })

  policy_rule = jsonencode({
    if = {
      field  = "tags['BusinessRequest']"
      exists = false
    }
    then = {
      effect = "[parameters('effect')]"
    }
  })
}


############################################################
# Policy: Require tag BusinessOwner
############################################################
resource "azurerm_policy_definition" "tag_businessowner_required" {
  name         = "tag-businessowner-required"
  display_name = "Require tag: BusinessOwner"
  description  = "Audits resources missing the 'BusinessOwner' tag."
  policy_type  = "Custom"
  mode         = "Indexed"
  metadata     = jsonencode({ category = "Tags" })

  parameters = jsonencode({
    effect = {
      type          = "String"
      metadata      = { displayName = "Effect" }
      allowedValues = ["Audit", "Deny", "Disabled"]
      defaultValue  = "Audit"
    }
  })

  policy_rule = jsonencode({
    if = {
      field  = "tags['BusinessOwner']"
      exists = false
    }
    then = {
      effect = "[parameters('effect')]"
    }
  })
}

############################################################
# Policy: Require tag CompanyCode
############################################################
resource "azurerm_policy_definition" "tag_companycode_required" {
  name         = "tag-companycode-required"
  display_name = "Require tag: CompanyCode"
  description  = "Audits resources missing the 'CompanyCode' tag."
  policy_type  = "Custom"
  mode         = "Indexed"
  metadata     = jsonencode({ category = "Tags" })

  parameters = jsonencode({
    effect = {
      type          = "String"
      metadata      = { displayName = "Effect" }
      allowedValues = ["Audit", "Deny", "Disabled"]
      defaultValue  = "Audit"
    }
  })

  policy_rule = jsonencode({
    if = {
      field  = "tags['CompanyCode']"
      exists = false
    }
    then = {
      effect = "[parameters('effect')]"
    }
  })
}

############################################################
# Policy: Require tag Scm
############################################################
resource "azurerm_policy_definition" "tag_scm_required" {
  name         = "tag-scm-required"
  display_name = "Require tag: Scm"
  description  = "Audits resources missing the 'Scm' tag."
  policy_type  = "Custom"
  mode         = "Indexed"
  metadata     = jsonencode({ category = "Tags" })

  parameters = jsonencode({
    effect = {
      type          = "String"
      metadata      = { displayName = "Effect" }
      allowedValues = ["Audit", "Deny", "Disabled"]
      defaultValue  = "Audit"
    }
  })

  policy_rule = jsonencode({
    if = {
      field  = "tags['Scm']"
      exists = false
    }
    then = {
      effect = "[parameters('effect')]"
    }
  })
}

############################################################
# Policy: Require tag Environment with allowed values
############################################################
resource "azurerm_policy_definition" "tag_environment_required_allowed" {
  name         = "tag-environment-required-and-allowed"
  display_name = "Require tag: Environment with allowed values"
  description  = "Audits resources missing the 'Environment' tag or having a value not in the approved list."
  policy_type  = "Custom"
  mode         = "Indexed"
  metadata     = jsonencode({ category = "Tags" })

  parameters = jsonencode({
    effect = {
      type          = "String"
      metadata      = { displayName = "Effect" }
      allowedValues = ["Audit", "Deny", "Disabled"]
      defaultValue  = "Audit"
    }
  })

  policy_rule = jsonencode({
    if = {
      anyOf = [
        {
          field  = "tags['Environment']"
          exists = false
        },
        {
          field = "tags['Environment']"
          notIn = local.env_allowed_values
        }
      ]
    }
    then = {
      effect = "[parameters('effect')]"
    }
  })
}

############################################################
# Policy: Require tag DataClassification with allowed values
############################################################
resource "azurerm_policy_definition" "tag_dataclassification_required_allowed" {
  name         = "tag-dataclassification-required-and-allowed"
  display_name = "Require tag: DataClassification with allowed values"
  description  = "Audits resources missing the 'DataClassification' tag or having a value not in the approved list."
  policy_type  = "Custom"
  mode         = "Indexed"
  metadata     = jsonencode({ category = "Tags" })

  parameters = jsonencode({
    effect = {
      type          = "String"
      metadata      = { displayName = "Effect" }
      allowedValues = ["Audit", "Deny", "Disabled"]
      defaultValue  = "Audit"
    }
  })

  policy_rule = jsonencode({
    if = {
      anyOf = [
        {
          field  = "tags['DataClassification']"
          exists = false
        },
        {
          field = "tags['DataClassification']"
          notIn = local.dc_allowed_values
        }
      ]
    }
    then = {
      effect = "[parameters('effect')]"
    }
  })
}

############################################################
# Policy: Require tag BusinessCriticality with allowed values
############################################################
resource "azurerm_policy_definition" "tag_businesscriticality_required_allowed" {
  name         = "tag-businesscriticality-required-and-allowed"
  display_name = "Require tag: BusinessCriticality with allowed values"
  description  = "Audits resources missing the 'BusinessCriticality' tag or having a value not in the approved list."
  policy_type  = "Custom"
  mode         = "Indexed"
  metadata     = jsonencode({ category = "Tags" })

  parameters = jsonencode({
    effect = {
      type          = "String"
      metadata      = { displayName = "Effect" }
      allowedValues = ["Audit", "Deny", "Disabled"]
      defaultValue  = "Audit"
    }
  })

  policy_rule = jsonencode({
    if = {
      anyOf = [
        {
          field  = "tags['BusinessCriticality']"
          exists = false
        },
        {
          field = "tags['BusinessCriticality']"
          notIn = local.bc_allowed_values
        }
      ]
    }
    then = {
      effect = "[parameters('effect')]"
    }
  })
}

############################################################
# Initiative (Policy Set Definition): Mandatory Tags
############################################################
resource "azurerm_policy_set_definition" "initiative_mandatory_tags" {
  name         = "initiative-mandatory-tags"
  display_name = "Mandatory Tags (Audit/Deny)"
  description  = "Initiative that requires key governance tags and enforces allowed values where applicable."
  policy_type  = "Custom"
  metadata     = jsonencode({ category = "Tags" })

  # Single effect parameter propagated to all included policies
  parameters = jsonencode({
    effect = {
      type          = "String"
      metadata      = { displayName = "Effect for all included policies" }
      allowedValues = ["Audit", "Deny", "Disabled"]
      defaultValue  = "Audit"
    }
  })

  # References


  policy_definition_reference {
    reference_id         = "CostCenterRequired"
    policy_definition_id = azurerm_policy_definition.tag_costcenter_required.id
    parameter_values = jsonencode({
      effect = { value = "[parameters('effect')]" }
    })
  }

  policy_definition_reference {
    reference_id         = "ProjectRequired"
    policy_definition_id = azurerm_policy_definition.tag_project_required.id
    parameter_values = jsonencode({
      effect = { value = "[parameters('effect')]" }
    })
  }

  policy_definition_reference {
    reference_id         = "BusinessRequestRequired"
    policy_definition_id = azurerm_policy_definition.tag_businessrequest_required.id
    parameter_values = jsonencode({
      effect = { value = "[parameters('effect')]" }
    })
  }
  policy_definition_reference {
    reference_id         = "BusinessOwnerRequired"
    policy_definition_id = azurerm_policy_definition.tag_businessowner_required.id
    parameter_values = jsonencode({
      effect = { value = "[parameters('effect')]" }
    })
  }

  policy_definition_reference {
    reference_id         = "CompanyCodeRequired"
    policy_definition_id = azurerm_policy_definition.tag_companycode_required.id
    parameter_values = jsonencode({
      effect = { value = "[parameters('effect')]" }
    })
  }

  policy_definition_reference {
    reference_id         = "ScmRequired"
    policy_definition_id = azurerm_policy_definition.tag_scm_required.id
    parameter_values = jsonencode({
      effect = { value = "[parameters('effect')]" }
    })
  }

  policy_definition_reference {
    reference_id         = "EnvironmentRequiredAllowed"
    policy_definition_id = azurerm_policy_definition.tag_environment_required_allowed.id
    parameter_values = jsonencode({
      effect = { value = "[parameters('effect')]" }
    })
  }

  policy_definition_reference {
    reference_id         = "DataClassificationRequiredAllowed"
    policy_definition_id = azurerm_policy_definition.tag_dataclassification_required_allowed.id
    parameter_values = jsonencode({
      effect = { value = "[parameters('effect')]" }
    })
  }

  policy_definition_reference {
    reference_id         = "BusinessCriticalityRequiredAllowed"
    policy_definition_id = azurerm_policy_definition.tag_businesscriticality_required_allowed.id
    parameter_values = jsonencode({
      effect = { value = "[parameters('effect')]" }
    })
  }
}

############################################################
# Assignment at Subscription scope
############################################################
resource "azurerm_subscription_policy_assignment" "initiative_mandatory_tags_assignment" {
  name                 = "assignment-initiative-mandatory-tags"
  display_name         = "Assignment: Mandatory Tags Initiative"
  description          = "Audits resources to ensure mandatory tags exist and values are compliant."
  policy_definition_id = azurerm_policy_set_definition.initiative_mandatory_tags.id
  subscription_id      = "/subscriptions/${var.subscription_id}"
  enforce              = true

  # Set the initiative-level effect here: Audit, Deny, or Disabled
  parameters = jsonencode({
    effect = { value = "Audit" }
  })
}
