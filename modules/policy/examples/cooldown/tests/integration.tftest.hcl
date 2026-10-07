run "creates_disabled_cooldown" {
  assert {
    condition     = output.policy.read_only
    error_message = "Cloudsmith did not recognize the upstream cooldown example."
  }
}
