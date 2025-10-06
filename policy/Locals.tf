
locals {
  env_allowed_values = ["Prod", "Stg", "Dev"]
  dc_allowed_values  = ["public", "internal", "confidential"]
  bc_allowed_values  = ["non-essential", "essential", "critical"]
}
