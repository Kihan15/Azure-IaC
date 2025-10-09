resource "azurerm_policy_definition" "this" {
  for_each     = var.policy_definitions
  name         = each.key
  policy_type  = "Custom"
  mode         = "All"
  display_name = each.value.display_name
  description  = each.value.description
  metadata     = jsonencode(each.value.metadata)
  parameters   = jsonencode(each.value.parameters)
  policy_rule  = jsonencode(each.value.policyRule)
}
