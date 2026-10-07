terraform {
  required_version = ">= 1.6"

  required_providers {
    http = {
      source  = "hashicorp/http"
      version = ">= 3.4"
    }
  }
}

data "http" "recipe" {
  url                = "https://raw.githubusercontent.com/cloudsmith-io/rego-recipes/fb6e34c937267ba07712ef32a9d216b1ca1ccd38/recipes/date-time/publish_date_cooldown.rego"
  request_timeout_ms = 30000

  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "The test could not download the cooldown recipe."
    }
  }
}

output "rego" {
  value = data.http.recipe.response_body
}
