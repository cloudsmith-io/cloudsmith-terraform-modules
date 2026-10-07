output "vulnerability_policy_slug_perms" {
  description = "The permanent slugs of the vulnerability policies, keyed by policy name."
  value       = { for name, policy in cloudsmith_vulnerability_policy.this : name => policy.slug_perm }
}

output "license_policy_slug_perms" {
  description = "The permanent slugs of the license policies, keyed by policy name."
  value       = { for name, policy in cloudsmith_license_policy.this : name => policy.slug_perm }
}

output "deny_policy_ids" {
  description = "The IDs of the package deny policies, keyed by policy name."
  value       = { for name, policy in cloudsmith_package_deny_policy.this : name => policy.id }
}
