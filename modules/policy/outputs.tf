output "slug_perm" {
  description = "The permanent slug of the policy."
  value       = cloudsmith_policy.this.slug_perm
}

output "name" {
  description = "The name of the policy."
  value       = cloudsmith_policy.this.name
}

output "precedence" {
  description = "The precedence of the policy."
  value       = cloudsmith_policy.this.precedence
}

output "version" {
  description = "The version of the Rego source. Cloudsmith increments it when the Rego changes. The provider does not show the new value until the next plan."
  value       = cloudsmith_policy.this.version
}

output "read_only" {
  description = "True when Cloudsmith marks the policy as read only. You can then change only the cooldown variables in the Rego."
  value       = cloudsmith_policy.this.read_only
}

output "is_cooldown" {
  description = "True when the policy is a cooldown policy: it has a HIDDEN action, is terminal, and is read only."
  value       = local.has_hidden_action && cloudsmith_policy.this.is_terminal && cloudsmith_policy.this.read_only
}

output "action_slug_perms" {
  description = "The permanent slugs of the policy actions, keyed by action name."
  value       = { for key, action in cloudsmith_policy_action.this : key => action.slug_perm }
}
