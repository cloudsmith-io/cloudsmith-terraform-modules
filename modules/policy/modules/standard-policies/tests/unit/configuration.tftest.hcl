mock_provider "cloudsmith" {}

variables {
  workspace = "unit-test"
}

run "empty_maps_create_nothing" {
  command = plan

  assert {
    condition = (
      length(output.vulnerability_policy_slug_perms) == 0 &&
      length(output.license_policy_slug_perms) == 0 &&
      length(output.deny_policy_ids) == 0
    )
    error_message = "Empty policy maps must not create policies."
  }
}

run "plans_policy_defaults" {
  command = plan

  variables {
    vulnerability_policies = { critical = {} }
    license_policies = {
      copyleft = { description = "Copyleft", spdx_identifiers = ["GPL-3.0-only"] }
    }
    deny_policies = { blocked = { package_query = "name:blocked" } }
  }

  assert {
    condition = (
      cloudsmith_vulnerability_policy.this["critical"].min_severity == "Critical" &&
      !cloudsmith_vulnerability_policy.this["critical"].on_violation_quarantine &&
      !cloudsmith_license_policy.this["copyleft"].allow_unknown_licenses &&
      cloudsmith_package_deny_policy.this["blocked"].enabled
    )
    error_message = "The configured policies must preserve the documented defaults."
  }
}

run "rejects_invalid_severity" {
  command = plan

  variables {
    vulnerability_policies = { invalid = { min_severity = "critical" } }
  }

  expect_failures = [var.vulnerability_policies]
}

run "rejects_blank_deny_query" {
  command = plan

  variables {
    deny_policies = { invalid = { package_query = " " } }
  }

  expect_failures = [var.deny_policies]
}

run "rejects_oversized_deny_query" {
  command = plan

  variables {
    deny_policies = { invalid = { package_query = join("", [for i in range(257) : "a"]) } }
  }

  expect_failures = [var.deny_policies]
}

run "accepts_maximum_deny_query_length" {
  command = plan

  variables {
    deny_policies = { valid = { package_query = join("", [for i in range(256) : "a"]) } }
  }

  assert {
    condition     = length(cloudsmith_package_deny_policy.this["valid"].package_query) == 256
    error_message = "A 256-character query must be accepted."
  }
}
