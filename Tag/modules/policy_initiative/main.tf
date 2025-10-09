resource "azurerm_policy_set_definition" "initiative" {
  name         = var.initiative_name
  display_name = var.display_name
  description  = var.description
  policy_type  = "Custom"
  #management_group_id = var.management_group_id
  metadata   = jsonencode({ category = var.category })
  parameters = jsonencode(var.initiative_parameters)

  # Crée dynamiquement une référence pour chaque politique membre.
  dynamic "policy_definition_reference" {
    # Itère sur le map des IDs de politiques
    for_each = var.member_policy_ids

    content {
      # La valeur est l'ID Azure de la politique
      policy_definition_id = policy_definition_reference.value

      # La clé est le nom de la politique, utilisé comme ID de référence
      reference_id = policy_definition_reference.key

      # Mappe le paramètre 'effect' de l'Initiative vers le paramètre 'effect' de chaque politique
      # Ceci suppose que toutes les politiques membres utilisent un paramètre appelé 'effect'.
      parameter_values = jsonencode({
        effect = { value = "[parameters('effect')]" }
      })
    }
  }
}