output "subscription_id" {
  value       = var.subscription_id
  description = "The ID of the subscription where policy is assigned"
}

output "tag_name" {
  value       = var.tag_name
  description = "The name of the required tag"
}

output "policy_definition_id" {
  value       = azurerm_policy_definition.deny_missing_tag.id
  description = "The ID of the policy definition"
}

output "policy_definition_name" {
  value       = azurerm_policy_definition.deny_missing_tag.name
  description = "The name of the policy definition"
}

