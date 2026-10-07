variables {
  name_prefix = "tf-module-test: "
  enabled     = false
  allowlist   = { entries = ["python:example-lib:1.2.3"] }
  blocklist   = { entries = ["npm:compromised-ui", "python:malicious-lib:0.1.0"] }
}

run "rejects_allowlist_entry_without_version" {
  command = plan

  variables {
    allowlist = { entries = ["python:example-lib"] }
  }

  expect_failures = [var.allowlist]
}

run "rejects_unknown_cooldown_format" {
  command = plan

  variables {
    cooldown = { supported_formats = ["python", "pypi"] }
  }

  expect_failures = [var.cooldown]
}

run "rejects_empty_cooldown_formats" {
  command = plan

  variables {
    cooldown = { supported_formats = [] }
  }

  expect_failures = [var.cooldown]
}

run "rejects_fractional_cooldown_days" {
  command = plan

  variables {
    cooldown = { within_past_days = 1.5 }
  }

  expect_failures = [var.cooldown]
}

run "skips_empty_lists_and_null_recipes" {
  command = plan

  variables {
    allowlist = {}
    blocklist = {}
    malware   = null
  }

  assert {
    condition     = toset(keys(output.rego)) == toset(["cooldown", "copyleft_licenses", "high_risk_vulnerabilities"])
    error_message = "The module planned policies for empty lists or null recipes."
  }
}

run "keeps_recipe_values_by_default" {
  command = plan

  assert {
    condition     = strcontains(output.rego.cooldown, "\nwithin_past_days := 3\n") && strcontains(output.rego.high_risk_vulnerabilities, "\ncvss_threshold := 7.0\n")
    error_message = "The module changed a recipe value that the caller did not set."
  }

  assert {
    condition     = output.policies.cooldown.name == "tf-module-test: Cooldown period"
    error_message = "The policy name does not come from the recipe METADATA title."
  }
}

run "renders_variables_into_rego" {
  command = plan

  variables {
    cooldown                  = { within_past_days = 14, excluded_repositories = ["internal$repo"], included_repositories = [] }
    high_risk_vulnerabilities = { cvss_threshold = 9, ignored_ids = ["CVE-2021-9999"] }
  }

  assert {
    condition     = strcontains(output.rego.high_risk_vulnerabilities, "\ncvss_threshold := 9.0\n")
    error_message = "The CVSS threshold is not a floating-point literal."
  }

  assert {
    condition     = strcontains(output.rego.high_risk_vulnerabilities, "\nignored_ids := {\n\t\"CVE-2021-9999\",\n}")
    error_message = "The ignored IDs are not a Rego set."
  }

  assert {
    condition     = strcontains(output.rego.cooldown, "\nwithin_past_days := 14\n") && strcontains(output.rego.cooldown, "\nexcluded_repositories := {\n\t\"internal$repo\",\n}\n")
    error_message = "The cooldown variables are not in the Rego."
  }

  assert {
    condition     = strcontains(output.rego.cooldown, "\nincluded_repositories := {}\n")
    error_message = "An empty set does not render as {}."
  }
}

run "rejects_unknown_recipes_ref" {
  command = plan

  variables {
    recipes_ref = "0000000000000000000000000000000000000000"
  }

  expect_failures = [data.http.recipe]
}

run "creates_baseline" {
  assert {
    condition     = length(output.policies) == 6
    error_message = "The module did not create the six baseline policies."
  }

  assert {
    condition     = output.policies.cooldown.read_only
    error_message = "Cloudsmith did not accept the cooldown policy."
  }

  assert {
    condition = [for key in ["cooldown", "copyleft_licenses", "high_risk_vulnerabilities", "allowlist", "blocklist", "malware"] :
    output.policies[key].precedence] == [10, 20, 30, 40, 50, 60]
    error_message = "The policies do not have the recommended precedence order."
  }
}

run "updates_read_only_cooldown_in_place" {
  variables {
    cooldown  = { within_past_days = 7, excluded_repositories = ["public"] }
    allowlist = { entries = ["python:example-lib:1.2.3", "npm:example-ui:4.5.6"] }
  }

  assert {
    condition     = output.policies.cooldown.slug_perm == run.creates_baseline.policies.cooldown.slug_perm
    error_message = "The cooldown policy was replaced instead of updated."
  }

  assert {
    condition     = output.policies.allowlist.slug_perm == run.creates_baseline.policies.allowlist.slug_perm
    error_message = "The allowlist policy was replaced instead of updated."
  }
}

run "reads_updated_cooldown_from_api" {
  module {
    source = "./tests/read_policy"
  }

  variables {
    slug_perm = run.creates_baseline.policies.cooldown.slug_perm
  }

  assert {
    condition     = output.policy.version == 2
    error_message = "The cooldown Rego version did not increase."
  }

  assert {
    condition     = strcontains(output.policy.rego, "within_past_days := 7\n") && strcontains(output.policy.rego, "excluded_repositories := {\n\t\"public\",\n}")
    error_message = "Cloudsmith does not have the updated cooldown variables."
  }

  assert {
    condition     = output.policy.read_only && output.policy.is_terminal && !output.policy.enabled
    error_message = "The cooldown policy flags changed."
  }
}
