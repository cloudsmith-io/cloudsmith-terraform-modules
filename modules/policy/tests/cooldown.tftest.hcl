# These runs prove that the module stops the apply when Cloudsmith does not keep a policy with a HIDDEN action as a cooldown policy.

run "downloads_cooldown_recipe" {
  module {
    source = "./tests/cooldown_recipe"
  }
}

run "creates_cooldown_policy" {
  variables {
    name        = "tf-module-test-cooldown"
    enabled     = false
    is_terminal = true
    rego        = run.downloads_cooldown_recipe.rego
    actions = {
      hide = { set_package_state = "HIDDEN" }
    }
  }

  assert {
    condition     = output.read_only
    error_message = "Cloudsmith did not accept the cooldown recipe as a cooldown policy."
  }
}

run "rejects_update_to_an_unsupported_format" {
  variables {
    name        = "tf-module-test-cooldown"
    enabled     = false
    is_terminal = true
    rego        = replace(run.downloads_cooldown_recipe.rego, "\"python\"", "\"pypi\"")
    actions = {
      hide = { set_package_state = "HIDDEN" }
    }
  }

  expect_failures = [cloudsmith_policy.this]
}
