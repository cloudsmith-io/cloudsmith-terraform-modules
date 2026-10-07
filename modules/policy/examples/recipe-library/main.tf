locals {
  recipes = toset([
    "date-time/publish_date_cooldown.rego",
    "date-time/upload_date.rego",
    "format-name-version/allowlist.rego",
    "format-name-version/blocklist.rego",
    "format-name-version/format_filename_pattern.rego",
    "format-name-version/minimum_version.rego",
    "format-name-version/repo_filename_contains.rego",
    "hugging-face/model_card.rego",
    "hugging-face/risky_files.rego",
    "hugging-face/security_scan.rego",
    "hugging-face/trusted_publishers.rego",
    "license/copyleft_licenses.rego",
    "metadata/architecture.rego",
    "metadata/tags.rego",
    "vulnerability/best_cvss_with_fix.rego",
    "vulnerability/cvss_with_fix.rego",
    "vulnerability/epss.rego",
    "vulnerability/id_blocklist.rego",
    "vulnerability/malware.rego",
  ])
  cooldown_recipe = "date-time/publish_date_cooldown.rego"
}

data "http" "recipe" {
  for_each = local.recipes

  url                = "https://raw.githubusercontent.com/cloudsmith-io/rego-recipes/master/recipes/${each.key}"
  request_timeout_ms = 30000

  retry {
    attempts = 3
  }

  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "Could not download recipe ${each.key}."
    }
  }
}

module "recipe" {
  source   = "../../"
  for_each = local.recipes

  workspace   = var.workspace
  name        = "Recipe example: ${regex("(?m)^# title: (.+)$", data.http.recipe[each.key].response_body)[0]}"
  description = regex("(?m)^# description: (.+)$", data.http.recipe[each.key].response_body)[0]
  rego        = data.http.recipe[each.key].response_body
  enabled     = false
  is_terminal = each.key == local.cooldown_recipe

  actions = {
    match = {
      set_package_state = each.key == local.cooldown_recipe ? "HIDDEN" : null
      add_package_tags  = each.key == local.cooldown_recipe ? null : ["recipe-${trimsuffix(basename(each.key), ".rego")}"]
    }
  }
}

output "policies" {
  description = "The disabled policies, keyed by recipe path."
  value = {
    for path, policy in module.recipe : path => {
      slug_perm = policy.slug_perm
      read_only = policy.read_only
    }
  }
}
