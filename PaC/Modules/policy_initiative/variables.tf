variable "policy_initiatives" {
  type = map(object({
    display_name = string
    description  = string
    metadata     = map(string)
    parameters   = map(any)
    policy_definition_references = list(object({
      policy_definition_id = string
      parameter_values     = map(any)
    }))
  }))
}
