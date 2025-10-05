variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID where the policy will be assigned"
}

variable "tag_name" {
  type        = string
  description = "The name of the required tag"
}

variable "location" {
  type        = string
  description = "The Azure region for the managed identity (required for modify policies)"
  default     = "westeurope"
}

variable "default_environment_value" {
  type        = string
  description = "The default value to set for invalid environment tags"
  default     = "dev"
  validation {
    condition     = contains(["prod", "stg", "dev"], var.default_environment_value)
    error_message = "Default environment value must be one of: prod, stg, dev"
  }
}