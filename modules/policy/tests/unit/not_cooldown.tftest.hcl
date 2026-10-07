mock_provider "cloudsmith" {}

variables {
  workspace = "unit-test"
  name      = "unit-test"
  rego      = "package cloudsmith\n\ndefault match := false\n"
}

run "accepts_terminal_policy_without_hidden_action" {
  variables {
    is_terminal = true
    actions     = { tag = { add_package_tags = ["review"] } }
  }

  override_resource {
    target = cloudsmith_policy.this
    values = { read_only = false }
  }

  assert {
    condition     = cloudsmith_policy.this.is_terminal && !output.is_cooldown
    error_message = "A terminal policy without a HIDDEN action must apply and must not be a cooldown policy."
  }
}
