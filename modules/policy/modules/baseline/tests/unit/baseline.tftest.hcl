mock_provider "cloudsmith" {}

variables {
  workspace = "unit-test"
  enabled   = false
}

run "plans_default_policies" {
  command = plan

  assert {
    condition     = toset(keys(output.rego)) == toset(["cooldown", "copyleft_licenses", "high_risk_vulnerabilities", "malware"])
    error_message = "Only the four default policies should be planned."
  }

  assert {
    condition     = strcontains(output.rego.cooldown, "\nwithin_past_days := 3\n")
    error_message = "Unset recipe variables must keep their upstream defaults."
  }
}

run "null_disables_every_policy" {
  command = plan

  variables {
    cooldown                  = null
    copyleft_licenses         = null
    high_risk_vulnerabilities = null
    allowlist                 = null
    blocklist                 = null
    malware                   = null
  }

  assert {
    condition     = length(output.rego) == 0 && length(output.policies) == 0
    error_message = "Null policies must not download recipes or create resources."
  }
}

run "renders_all_cooldown_variables" {
  command = plan

  variables {
    cooldown = {
      within_past_days       = 14
      supported_formats      = ["python", "npm"]
      included_repositories  = []
      excluded_repositories  = ["internal$repo", "quoted\"repo"]
      include_local_packages = true
    }
    high_risk_vulnerabilities = { cvss_threshold = 9, ignored_ids = ["CVE-2021-9999"] }
    copyleft_licenses         = { licenses = ["GPL-3.0-only"] }
    allowlist                 = { entries = ["npm:@scope/package:1.0.0"] }
    blocklist                 = { entries = ["python:example-package"] }
  }

  assert {
    condition = (
      strcontains(output.rego.cooldown, "\nwithin_past_days := 14\n") &&
      strcontains(output.rego.cooldown, "\nsupported_formats := {\n\t\"npm\",\n\t\"python\",\n}\n") &&
      strcontains(output.rego.cooldown, "\nincluded_repositories := {}\n") &&
      strcontains(output.rego.cooldown, "\nexcluded_repositories := {\n\t\"internal$repo\",\n\t\"quoted\\\"repo\",\n}\n") &&
      strcontains(output.rego.cooldown, "\ninclude_local_packages := true\n")
    )
    error_message = "All five cooldown variables must be rendered with valid string escaping."
  }

  assert {
    condition     = strcontains(output.rego.high_risk_vulnerabilities, "\ncvss_threshold := 9.0\n")
    error_message = "Integer CVSS values must render as floating-point literals."
  }

  assert {
    condition = (
      strcontains(output.rego.copyleft_licenses, "\ncopyleft := {\n\t\"GPL-3.0-only\",\n}\n") &&
      !strcontains(output.rego.copyleft_licenses, "MPL-2.0") &&
      strcontains(output.rego.allowlist, "\nallowlist := {\n\t\"npm:@scope/package:1.0.0\",\n}\n") &&
      strcontains(output.rego.blocklist, "\nblocklist := {\n\t\"python:example-package\",\n}\n")
    )
    error_message = "Set substitutions must replace the complete recipe defaults, including multiline sets."
  }
}

run "rejects_mutable_recipe_ref" {
  command = plan

  variables {
    recipes_ref = "main"
  }

  expect_failures = [var.recipes_ref]
}

run "rejects_out_of_range_cvss" {
  command = plan

  variables {
    high_risk_vulnerabilities = { cvss_threshold = 10.1 }
  }

  expect_failures = [var.high_risk_vulnerabilities]
}

run "rejects_negative_cvss" {
  command = plan

  variables {
    high_risk_vulnerabilities = { cvss_threshold = -1 }
  }

  expect_failures = [var.high_risk_vulnerabilities]
}

run "rejects_empty_allowlist_component" {
  command = plan

  variables {
    allowlist = { entries = ["python::1.0.0"] }
  }

  expect_failures = [var.allowlist]
}

run "rejects_empty_blocklist_component" {
  command = plan

  variables {
    blocklist = { entries = ["python:"] }
  }

  expect_failures = [var.blocklist]
}

run "rejects_fractional_cooldown" {
  command = plan

  variables {
    cooldown = { within_past_days = 1.5 }
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
