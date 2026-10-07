variables {
  name_prefix = "tf-module-test: "
  enabled     = false
  allowlist   = { entries = ["python:example-lib:1.2.3"] }
  blocklist   = { entries = ["npm:compromised-ui", "python:malicious-lib:0.1.0"] }
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
