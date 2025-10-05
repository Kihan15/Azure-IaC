###############################################################################
# 1  TERRAFORM BLOCK & AZURE PROVIDER CONFIGURATION
###############################################################################
terraform {
  required_version = ">= 1.5.7"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.74.0"
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

