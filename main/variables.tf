variable "target_subscription_id" {
  description = "The Azure Subscription ID for resource deployment."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
  default     = "rg-prod-app"
}

variable "location" {
  description = "Azure region for resource deployment."
  type        = string
  default     = "East US"
}

variable "storage_account_name" {
  description = "Globally unique name for the storage account (lowercase)."
  type        = string
  default     = "tfmgstorageacnt"
}

variable "tags" {
  description = "Tags to assign to resources."
  type        = map(string)
  default     = {
    environment = "Production"
    project     = "OIDC-Demo"
  }
}


# Data source to get the management group ID for Policy

variable "management_group_id" {
  description = "The ID of the Management Group where the policy will be assigned (e.g., 'Contoso-MG')."
  type        = string
}

variable "tag_name" {
  description = "The name of the tag to audit for."
  type        = string
  default     = "Environment"
}