data "http" "epss_recipe" {
  url                = "https://raw.githubusercontent.com/cloudsmith-io/rego-recipes/fb6e34c937267ba07712ef32a9d216b1ca1ccd38/recipes/vulnerability/epss.rego"
  request_timeout_ms = 30000

  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "The example could not download the EPSS recipe."
    }
  }
}

module "exploitation_risk" {
  source = "../../"

  workspace   = var.workspace
  name        = "Exploitation risk"
  description = "Tag packages with vulnerabilities that have an elevated risk of exploitation, based on EPSS."
  rego        = data.http.epss_recipe.response_body
  precedence  = 35

  actions = {
    tag = {
      add_package_tags = ["high-epss"]
    }
  }
}

output "slug_perm" {
  value = module.exploitation_risk.slug_perm
}
