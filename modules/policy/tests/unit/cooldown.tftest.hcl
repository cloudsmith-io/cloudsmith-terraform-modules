mock_provider "cloudsmith" {}

variables {
  workspace = "unit-test"
  name      = "unit-test"
  rego      = "package cloudsmith\n\ndefault match := false\n"
}

run "reports_hidden_terminal_read_only_policy_as_cooldown" {
  variables {
    actions = { hide = { set_package_state = "HIDDEN" } }
  }

  override_resource {
    target = cloudsmith_policy.this
    values = { read_only = true }
  }

  assert {
    condition     = output.is_cooldown
    error_message = "A policy with a HIDDEN action that is terminal and read only must be a cooldown policy."
  }
}
