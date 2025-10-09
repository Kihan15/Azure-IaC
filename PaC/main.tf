terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}


############################################################

# Policy Definitions 

############################################################

locals {
  policy_files = fileset("${path.module}/policy", "*.json")

  policy_definitions = {
    for file in local.policy_files :
    trimsuffix(file, ".json") => {
      display_name = jsondecode(file("${path.module}/policy/${file}")).displayName
      description  = jsondecode(file("${path.module}/policy/${file}")).description
      metadata     = jsondecode(file("${path.module}/policy/${file}")).metadata
      parameters   = jsondecode(file("${path.module}/policy/${file}")).parameters
      policyRule   = jsondecode(file("${path.module}/policy/${file}")).policyRule
      policy_type  = jsondecode(file("${path.module}/policy/${file}")).policyType
      mode         = jsondecode(file("${path.module}/policy/${file}")).mode
    }
  }
}

module "policy_definitions" {
  source             = "./modules/policy_definition"
  policy_definitions = local.policy_definitions
}


############################################################
# Policy Initiatives
############################################################

locals {
  initiative_files = fileset("${path.module}/initiative", "*.json")

  policy_initiatives = {
    for file in local.initiative_files : trimsuffix(file, ".json") => jsondecode(file("${path.module}/initiative/${file}"))
  }
}

module "policy_initiatives" {
  source = "./modules/policy_initiative"
  policy_initiatives = local.policy_initiatives
}
