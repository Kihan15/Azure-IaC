###############################################################################
# 1. TERRAFORM BLOCK & AZURE PROVIDER CONFIGURATION
###############################################################################
terraform {
  required_version = ">= 1.1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

###############################################################################
# 2. CORE AZURE PROVIDER (OIDC from GitHub Actions)
###############################################################################
provider "azurerm" {
  features {}
}

###############################################################################
# 3. TARGET SUBSCRIPTION PROVIDER (ALIAS FOR SCOPED RESOURCES)
###############################################################################
provider "azurerm" {
  features        {}
  alias           = "target_sub"
  subscription_id = var.target_subscription_id
}

###############################################################################
# 4. RESOURCE GROUP CREATION
###############################################################################
resource "azurerm_resource_group" "main" {
  provider = azurerm.target_sub
  name     = "${var.resource_group_name}-${substr(var.target_subscription_id, 0, 8)}"
  location = var.location
  tags     = var.tags
}

###############################################################################
# 5. STORAGE ACCOUNT CREATION
###############################################################################
resource "azurerm_storage_account" "main" {
  provider                  = azurerm.target_sub
  name                      = "${var.storage_account_name}${substr(var.target_subscription_id, 0, 8)}"
  resource_group_name       = azurerm_resource_group.main.name
  location                  = azurerm_resource_group.main.location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  min_tls_version           = "TLS1_2"

  tags = merge(var.tags, { resource = "storage-account" })
}

###############################################################################
# 6. OUTPUTS
###############################################################################
output "storage_account_blob_endpoint" {
  description = "The primary blob endpoint of the created Storage Account."
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "resource_group_name" {
  description = "The name of the created resource group."
  value       = azurerm_resource_group.main.name
}

# Data source to get the management group ID
data "azurerm_management_group" "mg" {
  name = var.management_group_id # Use the ID of your Management Group (e.g., "my-root-mg")
}

# 1. Define the custom policy to audit for a missing tag
resource "azurerm_policy_definition" "audit_missing_tag" {
  name                = "audit-missing-${var.tag_name}-tag-mg"
  policy_type         = "Custom"
  mode                = "Indexed"
  display_name        = "Audit resources missing the '${var.tag_name}' tag"
  management_group_id = data.azurerm_management_group.mg.id
  description         = "Audits any resource missing the required tag for governance."

  # Policy rule defines the logic (in JSON format)
  policy_rule = file("policy-rule.json")

  # Policy parameters
  parameters = jsonencode({
    tagName = {
      type         = "String"
      metadata     = {
        display_name = "Tag Name"
        description  = "The name of the tag to audit for."
      }
    }
  })
}

# 2. Assign the policy to the Management Group
resource "azurerm_management_group_policy_assignment" "mg_tag_audit_assignment" {
  name                   = "assign-${azurerm_policy_definition.audit_missing_tag.name}"
  management_group_id    = data.azurerm_management_group.mg.id
  policy_definition_id   = azurerm_policy_definition.audit_missing_tag.id
  display_name           = "Audit missing ${var.tag_name} tag on all resources (MG Assignment)"
  
  # Set the parameter value for the assignment
  parameters = jsonencode({
    tagName = {
      value = var.tag_name
    }
  })
}