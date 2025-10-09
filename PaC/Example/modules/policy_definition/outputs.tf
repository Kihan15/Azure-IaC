output "policy_definition_id" {
  description = "The ID of the Azure Policy Definition created by this module instance."
  # This refers to the resource defined in modules/policy_definition/main.tf
  value = azurerm_policy_definition.def_policies.id
}