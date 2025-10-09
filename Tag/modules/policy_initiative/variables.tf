variable "initiative_name" {
  description = "The unique name of the Policy Initiative (Policy Set Definition)."
  type        = string
}

variable "display_name" {
  description = "The human-readable display name for the Policy Initiative."
  type        = string
}

variable "description" {
  description = "The description for the Policy Initiative."
  type        = string
}

variable "category" {
  description = "The category for the Policy Initiative (e.g., 'Tags', 'Security')."
  type        = string
}

variable "management_group_id" {
  description = "The Management Group ID where the Initiative will be defined."
  type        = string
}

variable "initiative_parameters" {
  description = "A map of parameters defined at the Initiative level."
  type        = map(any)
  default     = {}
}

variable "member_policy_ids" {
  description = "A map containing the policy name (key) and the Azure Policy Definition ID (value)."
  type        = map(string)
}