variables {
  name        = "tf-module-test-policy"
  description = "Created by the terraform test of the policy module."
  enabled     = false
  rego        = <<-EOT
    package cloudsmith

    default match := false

    match if "tf-module-test" in {tag.name | some tag in input.v0.package.tags}
  EOT
  actions = {
    quarantine = {
      set_package_state = "QUARANTINED"
      precedence        = 1
    }
    tag = {
      add_package_tags = ["tf-module-test-matched"]
      precedence       = 2
    }
  }
}

run "rejects_hidden_action_on_a_policy_that_is_not_a_cooldown_policy" {
  variables {
    name        = "tf-module-test-not-an-index-policy"
    is_terminal = true
    actions = {
      hide = { set_package_state = "HIDDEN" }
    }
  }

  expect_failures = [cloudsmith_policy.this]
}

run "creates_policy_with_actions" {
  assert {
    condition     = output.slug_perm != ""
    error_message = "The policy has no slug_perm."
  }

  assert {
    condition     = toset(keys(output.action_slug_perms)) == toset(["quarantine", "tag"])
    error_message = "The module did not create both actions."
  }

  assert {
    condition     = cloudsmith_policy_action.this["tag"].add_package_tags[0].tags == toset(["tf-module-test-matched"])
    error_message = "The tag action has the wrong tags."
  }
}

run "updates_policy_in_place" {
  variables {
    description = "Updated by the terraform test of the policy module."
    actions = {
      quarantine = {
        set_package_state = "AVAILABLE"
        precedence        = 1
      }
    }
  }

  assert {
    condition     = cloudsmith_policy.this.description == "Updated by the terraform test of the policy module."
    error_message = "The description did not update."
  }

  assert {
    condition     = toset(keys(output.action_slug_perms)) == toset(["quarantine"])
    error_message = "The module did not remove the tag action."
  }

  assert {
    condition     = cloudsmith_policy_action.this["quarantine"].set_package_state[0].package_state == "AVAILABLE"
    error_message = "The quarantine action state did not update."
  }
}
