variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "tag_name" {
  type        = string
  description = "Single tag name to be used in policy"
}
variable "mandatory_tags" {
  type        = list(string)
  description = "List of mandatory tags to audit"
}
