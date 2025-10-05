variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID where the policy will be assigned"
}

variable "tag_name" {
  type        = string
  description = "The name of the required tag"
}