variable "policy_definitions" {
  type = map(object({
    display_name = string
    description  = string
    metadata     = map(any)
    parameters   = map(any)
    policyRule   = any
    policy_type  = string
    mode         = string
  }))
}
