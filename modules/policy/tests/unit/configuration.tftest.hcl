mock_provider "cloudsmith" {}

variables {
  workspace = "unit-test"
  name      = "unit-test"
  rego      = "package cloudsmith\n\ndefault match := false\n"
}

run "defaults_to_no_actions" {
  command = plan

  assert {
    condition     = length(cloudsmith_policy_action.this) == 0
    error_message = "An empty action map must not create actions."
  }

  expect_failures = [check.actions]
}

run "plans_all_action_types" {
  command = plan

  variables {
    actions = {
      state  = { set_package_state = "QUARANTINED", precedence = 1 }
      add    = { add_package_tags = ["review"], precedence = 2 }
      remove = { remove_package_tags = ["approved"], precedence = 3 }
    }
  }

  assert {
    condition = (
      cloudsmith_policy_action.this["state"].set_package_state[0].package_state == "QUARANTINED" &&
      cloudsmith_policy_action.this["add"].add_package_tags[0].tags == toset(["review"]) &&
      cloudsmith_policy_action.this["remove"].remove_package_tags[0].tags == toset(["approved"])
    )
    error_message = "Each action must preserve its effect and tags."
  }
}

run "rejects_empty_action" {
  command = plan

  variables {
    actions = { empty = {} }
  }

  expect_failures = [var.actions]
}

run "rejects_two_effects_even_with_empty_state" {
  command = plan

  variables {
    actions = { invalid = { set_package_state = "", add_package_tags = ["review"] } }
  }

  expect_failures = [var.actions]
}

run "rejects_unknown_state" {
  command = plan

  variables {
    actions = { invalid = { set_package_state = "INVALID" } }
  }

  expect_failures = [var.actions]
}

run "rejects_fractional_policy_precedence" {
  command = plan

  variables {
    precedence = 1.5
  }

  expect_failures = [var.precedence, check.actions]
}

run "rejects_fractional_action_precedence" {
  command = plan

  variables {
    actions = { invalid = { add_package_tags = ["review"], precedence = 1.5 } }
  }

  expect_failures = [var.actions]
}

run "rejects_non_terminal_hidden_action" {
  command = plan

  variables {
    is_terminal = false
    actions     = { hide = { set_package_state = "HIDDEN" } }
  }

  expect_failures = [cloudsmith_policy.this]
}

run "makes_hidden_action_terminal_by_default" {
  command = plan

  variables {
    actions = { hide = { set_package_state = "HIDDEN" } }
  }

  assert {
    condition     = cloudsmith_policy.this.is_terminal
    error_message = "A policy with a HIDDEN action must be terminal by default."
  }
}

run "makes_policy_without_hidden_action_not_terminal_by_default" {
  command = plan

  assert {
    condition     = !cloudsmith_policy.this.is_terminal
    error_message = "A policy without a HIDDEN action must not be terminal by default."
  }

  expect_failures = [check.actions]
}

run "rejects_hidden_action_when_api_does_not_recognize_cooldown" {
  variables {
    is_terminal = true
    actions     = { hide = { set_package_state = "HIDDEN" } }
  }

  override_resource {
    target = cloudsmith_policy.this
    values = { read_only = false }
  }

  expect_failures = [cloudsmith_policy.this]
}
