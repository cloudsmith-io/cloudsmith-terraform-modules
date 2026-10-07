module "standard_policies" {
  source = "../../modules/standard-policies"

  workspace = var.workspace

  vulnerability_policies = {
    "Critical vulnerabilities" = {
      description             = "Quarantine Python packages with a critical vulnerability."
      min_severity            = "Critical"
      on_violation_quarantine = true
      package_query_string    = "format:python"
    }
  }

  license_policies = {
    "Strong copyleft" = {
      description             = "Quarantine packages with a strong copyleft license."
      spdx_identifiers        = ["AGPL-3.0-only", "GPL-3.0-only"]
      on_violation_quarantine = true
    }
  }

  deny_policies = {
    "Compromised versions" = {
      description   = "Block known compromised versions."
      package_query = "format:npm AND name:^example-ui$ AND version:4.5.6"
    }
  }
}
