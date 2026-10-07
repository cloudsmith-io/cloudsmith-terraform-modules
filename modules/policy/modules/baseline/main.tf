locals {
  # Matches a top-level Rego assignment with a scalar value or a set literal that can span lines.
  variable_pattern = "(?m)^%s := (?:\\{[^{}]*\\}|[^\\n]*)"

  set_values = {
    "cooldown.supported_formats"            = try(var.cooldown.supported_formats, null)
    "cooldown.included_repositories"        = try(var.cooldown.included_repositories, null)
    "cooldown.excluded_repositories"        = try(var.cooldown.excluded_repositories, null)
    "copyleft_licenses.copyleft"            = try(var.copyleft_licenses.licenses, null)
    "high_risk_vulnerabilities.ignored_ids" = try(var.high_risk_vulnerabilities.ignored_ids, null)
    "allowlist.allowlist"                   = var.allowlist.entries
    "blocklist.blocklist"                   = var.blocklist.entries
  }

  # Rego reads `{}` as an empty object. The recipes use it as an empty set.
  rego_sets = {
    for key, values in local.set_values :
    key => values == null ? null : length(values) == 0 ? "{}" : "{\n${join("", [for value in sort(values) : "\t${jsonencode(value)},\n"])}}"
  }

  cvss_threshold = try(var.high_risk_vulnerabilities.cvss_threshold, null)

  recipes = {
    cooldown = var.cooldown == null ? null : {
      path        = "date-time/publish_date_cooldown.rego"
      is_terminal = true
      precedence  = var.cooldown.precedence
      name        = var.cooldown.name
      description = var.cooldown.description
      enabled     = var.cooldown.enabled
      actions     = var.cooldown.actions
      variables = tomap({
        within_past_days       = var.cooldown.within_past_days == null ? null : tostring(var.cooldown.within_past_days)
        supported_formats      = local.rego_sets["cooldown.supported_formats"]
        included_repositories  = local.rego_sets["cooldown.included_repositories"]
        excluded_repositories  = local.rego_sets["cooldown.excluded_repositories"]
        include_local_packages = var.cooldown.include_local_packages == null ? null : tostring(var.cooldown.include_local_packages)
      })
    }
    copyleft_licenses = var.copyleft_licenses == null ? null : {
      path        = "license/copyleft_licenses.rego"
      is_terminal = false
      precedence  = var.copyleft_licenses.precedence
      name        = var.copyleft_licenses.name
      description = var.copyleft_licenses.description
      enabled     = var.copyleft_licenses.enabled
      actions     = var.copyleft_licenses.actions
      variables   = tomap({ copyleft = local.rego_sets["copyleft_licenses.copyleft"] })
    }
    high_risk_vulnerabilities = var.high_risk_vulnerabilities == null ? null : {
      path        = "vulnerability/cvss_with_fix.rego"
      is_terminal = false
      precedence  = var.high_risk_vulnerabilities.precedence
      name        = var.high_risk_vulnerabilities.name
      description = var.high_risk_vulnerabilities.description
      enabled     = var.high_risk_vulnerabilities.enabled
      actions     = var.high_risk_vulnerabilities.actions
      variables = tomap({
        # The recipe formats the threshold with %.1f, which needs a floating-point literal.
        cvss_threshold = local.cvss_threshold == null ? null : floor(local.cvss_threshold) == local.cvss_threshold ? format("%.1f", local.cvss_threshold) : tostring(local.cvss_threshold)
        ignored_ids    = local.rego_sets["high_risk_vulnerabilities.ignored_ids"]
      })
    }
    allowlist = length(var.allowlist.entries) == 0 ? null : {
      path        = "format-name-version/allowlist.rego"
      is_terminal = false
      precedence  = var.allowlist.precedence
      name        = var.allowlist.name
      description = var.allowlist.description
      enabled     = var.allowlist.enabled
      actions     = var.allowlist.actions
      variables   = tomap({ allowlist = local.rego_sets["allowlist.allowlist"] })
    }
    blocklist = length(var.blocklist.entries) == 0 ? null : {
      path        = "format-name-version/blocklist.rego"
      is_terminal = false
      precedence  = var.blocklist.precedence
      name        = var.blocklist.name
      description = var.blocklist.description
      enabled     = var.blocklist.enabled
      actions     = var.blocklist.actions
      variables   = tomap({ blocklist = local.rego_sets["blocklist.blocklist"] })
    }
    malware = var.malware == null ? null : {
      path        = "vulnerability/malware.rego"
      is_terminal = false
      precedence  = var.malware.precedence
      name        = var.malware.name
      description = var.malware.description
      enabled     = var.malware.enabled
      actions     = var.malware.actions
      variables   = tomap({})
    }
  }

  selected_recipes = { for key, recipe in local.recipes : key => recipe if recipe != null }

  # Each recipe gets five substitutions. The padding pattern matches nothing.
  substitutions = {
    for key, recipe in local.selected_recipes : key => concat(
      [
        for name, value in recipe.variables : {
          pattern     = "/${format(local.variable_pattern, name)}/"
          replacement = "${name} := ${replace(value, "$", "$$")}"
        } if value != null
      ],
      [for index in range(5) : { pattern = "/[^\\s\\S]/", replacement = "" }],
    )
  }

  rego = {
    for key, steps in local.substitutions : key => replace(replace(replace(replace(replace(
      data.http.recipe[key].response_body,
      steps[0].pattern, steps[0].replacement),
      steps[1].pattern, steps[1].replacement),
      steps[2].pattern, steps[2].replacement),
      steps[3].pattern, steps[3].replacement),
    steps[4].pattern, steps[4].replacement)
  }
}

data "http" "recipe" {
  for_each = local.selected_recipes

  url                = "${var.recipes_url}/${var.recipes_ref}/recipes/${each.value.path}"
  request_timeout_ms = 30000

  retry {
    attempts = 3
  }

  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "The module could not download the recipe. Check recipes_url and recipes_ref."
    }

    postcondition {
      condition     = can(regex("(?m)^# title: .+$", self.response_body)) && can(regex("(?m)^# description: .+$", self.response_body))
      error_message = "The recipe does not have a METADATA title and description."
    }

    postcondition {
      condition = alltrue([
        for name, value in each.value.variables :
        value == null || length(regexall(format(local.variable_pattern, name), self.response_body)) == 1
      ])
      error_message = "The recipe does not define each variable that the module sets. Check recipes_ref."
    }
  }
}

module "policy" {
  source   = "../../"
  for_each = local.selected_recipes

  workspace   = var.workspace
  name        = "${var.name_prefix}${coalesce(each.value.name, regex("(?m)^# title: (.+)$", data.http.recipe[each.key].response_body)[0])}"
  description = coalesce(each.value.description, regex("(?m)^# description: (.+)$", data.http.recipe[each.key].response_body)[0])
  enabled     = coalesce(each.value.enabled, var.enabled)
  rego        = local.rego[each.key]
  is_terminal = each.value.is_terminal
  precedence  = each.value.precedence
  actions     = each.value.actions
}
