resource "azurerm_policy_set_definition" "this" {
  for_each     = var.policy_initiatives
  name         = each.key
  policy_type  = "Custom"
  display_name = each.value.display_name
  description  = each.value.description
  metadata     = jsonencode(each.value.metadata)
  parameters   = jsonencode(each.value.parameters)

  dynamic "policy_definition_reference" {
    for_each = each.value.policy_definition_references
    content {
      policy_definition_id = policy_definition_reference.value.policy_definition_id
      parameter_values     = jsonencode(policy_definition_reference.value.parameter_values)
    }
  }
}
