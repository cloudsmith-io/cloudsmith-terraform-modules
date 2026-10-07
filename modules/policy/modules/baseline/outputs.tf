output "policies" {
  description = "The created policies, keyed by recipe name."
  value = {
    for key, policy in module.policy : key => {
      name              = policy.name
      slug_perm         = policy.slug_perm
      precedence        = policy.precedence
      read_only         = policy.read_only
      is_cooldown       = policy.is_cooldown
      action_slug_perms = policy.action_slug_perms
    }
  }
}

output "rego" {
  description = "The rendered Rego source of each created policy, keyed by recipe name."
  value       = local.rego
}
