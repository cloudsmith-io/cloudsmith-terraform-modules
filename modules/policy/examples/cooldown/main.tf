data "http" "recipe" {
  url                = "https://raw.githubusercontent.com/cloudsmith-io/rego-recipes/master/recipes/date-time/publish_date_cooldown.rego"
  request_timeout_ms = 30000

  retry {
    attempts = 3
  }

  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "Could not download the cooldown recipe."
    }
  }
}

module "cooldown" {
  source = "../../"

  workspace   = var.workspace
  name        = "Upstream package cooldown"
  description = "New upstream versions are hidden until they reach the recipe's minimum age."
  rego        = data.http.recipe.response_body
  enabled     = var.enabled
  is_terminal = true
  precedence  = 10

  actions = {
    hide = { set_package_state = "HIDDEN" }
  }
}

output "policy" {
  description = "The cooldown policy identity and recognition status."
  value = {
    slug_perm   = module.cooldown.slug_perm
    is_cooldown = module.cooldown.is_cooldown
  }
}
