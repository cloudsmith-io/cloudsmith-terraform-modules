run "creates_disabled_cooldown" {
  assert {
    condition     = output.policy.is_cooldown
    error_message = "Cloudsmith did not recognize the upstream cooldown example."
  }
}
