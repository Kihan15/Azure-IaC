variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "tag_name" {
  type        = string
<<<<<<< HEAD
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
=======
  description = "Single tag name to be used in policy"
}
variable "mandatory_tags" {
  type        = list(string)
  description = "List of mandatory tags to audit"
}
>>>>>>> 8469c7d26b595d0dcb76ffdf0279f75c426504dc
