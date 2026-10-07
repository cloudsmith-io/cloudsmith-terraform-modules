run "creates_every_recipe" {
  assert {
    condition     = length(output.policies) == 19 && alltrue([for policy in values(output.policies) : policy.slug_perm != ""])
    error_message = "Every recipe must create a policy."
  }

  assert {
    condition     = output.policies["date-time/publish_date_cooldown.rego"].is_cooldown
    error_message = "Cloudsmith did not recognize the cooldown recipe."
  }
}
