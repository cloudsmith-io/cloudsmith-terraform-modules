resource "cloudsmith_vulnerability_policy" "this" {
  for_each = var.vulnerability_policies

  organization            = var.workspace
  name                    = each.key
  description             = each.value.description
  min_severity            = each.value.min_severity
  on_violation_quarantine = each.value.on_violation_quarantine
  allow_unknown_severity  = each.value.allow_unknown_severity
  package_query_string    = each.value.package_query_string
}

resource "cloudsmith_license_policy" "this" {
  for_each = var.license_policies

  organization            = var.workspace
  name                    = each.key
  description             = each.value.description
  spdx_identifiers        = each.value.spdx_identifiers
  on_violation_quarantine = each.value.on_violation_quarantine
  allow_unknown_licenses  = each.value.allow_unknown_licenses
  package_query_string    = each.value.package_query_string
}

resource "cloudsmith_package_deny_policy" "this" {
  for_each = var.deny_policies

  namespace     = var.workspace
  name          = each.key
  description   = each.value.description
  package_query = each.value.package_query
  enabled       = each.value.enabled
}
