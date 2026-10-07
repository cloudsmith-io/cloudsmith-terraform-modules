# six 1.17.0 was published on 2024-12-04, and six 1.16.0 on 2021-05-05.
# A 1000-day window hides 1.17.0 until 2027-08-31. A 400-day window does not hide it.

variables {
  enabled          = false
  within_past_days = 1000
}

run "creates_a_disabled_cooldown_policy" {
  assert {
    condition     = output.cooldown.read_only
    error_message = "Cloudsmith did not accept the cooldown policy."
  }
}

run "disabled_policy_lists_every_version" {
  module {
    source = "./probe"
  }

  variables {
    download_root = run.creates_a_disabled_cooldown_policy.download_root
    request_id    = "disabled-${run.creates_a_disabled_cooldown_policy.request_id}"
  }

  assert {
    condition     = contains(output.listed_versions, "1.17.0") && contains(output.listed_versions, "1.16.0")
    error_message = "The index does not list six 1.17.0 and 1.16.0."
  }
}

run "enables_the_cooldown_policy" {
  variables {
    enabled = true
  }

  assert {
    condition     = output.cooldown.read_only
    error_message = "Cloudsmith did not accept the cooldown policy."
  }
}

run "enabled_policy_hides_the_new_version" {
  module {
    source = "./probe"
  }

  variables {
    download_root     = run.creates_a_disabled_cooldown_policy.download_root
    request_id        = "enabled-${run.creates_a_disabled_cooldown_policy.request_id}"
    download_versions = ["1.16.0", "1.17.0"]
  }

  assert {
    condition     = !contains(output.listed_versions, "1.17.0")
    error_message = "The index lists six 1.17.0, which is inside the cooldown window."
  }

  assert {
    condition     = contains(output.listed_versions, "1.16.0")
    error_message = "The index does not list six 1.16.0, which is outside the cooldown window."
  }

  assert {
    condition     = output.download_status["1.17.0"] == 403
    error_message = "The download of six 1.17.0 is not blocked."
  }

  assert {
    condition     = output.download_status["1.16.0"] == 200
    error_message = "The download of six 1.16.0 is blocked."
  }
}

run "shortens_the_cooldown_window" {
  variables {
    enabled          = true
    within_past_days = 400
  }

  assert {
    condition     = output.cooldown.read_only
    error_message = "Cloudsmith did not accept the changed cooldown policy."
  }
}

run "shorter_window_lists_the_version_again" {
  module {
    source = "./probe"
  }

  variables {
    download_root = run.creates_a_disabled_cooldown_policy.download_root
    request_id    = "shorter-${run.creates_a_disabled_cooldown_policy.request_id}"
  }

  assert {
    condition     = contains(output.listed_versions, "1.17.0")
    error_message = "The index does not list six 1.17.0 after the cooldown window became shorter."
  }
}
