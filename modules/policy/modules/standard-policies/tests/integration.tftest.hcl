variables {
  vulnerability_policies = {
    "tf-module-test: critical vulnerabilities" = {
      description          = "Created by the terraform test of the standard-policies module."
      min_severity         = "Critical"
      package_query_string = "name:tf-module-test-does-not-exist"
    }
  }
  license_policies = {
    "tf-module-test: strong copyleft" = {
      description          = "Created by the terraform test of the standard-policies module."
      spdx_identifiers     = ["AGPL-3.0-only", "GPL-3.0-only"]
      package_query_string = "name:tf-module-test-does-not-exist"
    }
  }
  deny_policies = {
    "tf-module-test: deny" = {
      description   = "Created by the terraform test of the standard-policies module."
      package_query = "name:^tf-module-test-does-not-exist$"
      enabled       = false
    }
  }
}

run "creates_policies" {
  assert {
    condition     = length(output.vulnerability_policy_slug_perms) == 1 && length(output.license_policy_slug_perms) == 1 && length(output.deny_policy_ids) == 1
    error_message = "The module did not create one policy of each type."
  }
}

run "updates_policies_in_place" {
  variables {
    vulnerability_policies = {
      "tf-module-test: critical vulnerabilities" = {
        description          = "Created by the terraform test of the standard-policies module."
        min_severity         = "High"
        package_query_string = "name:tf-module-test-does-not-exist"
      }
    }
    license_policies = {
      "tf-module-test: strong copyleft" = {
        description          = "Created by the terraform test of the standard-policies module."
        spdx_identifiers     = ["AGPL-3.0-only", "GPL-3.0-only", "SSPL-1.0"]
        package_query_string = "name:tf-module-test-does-not-exist"
      }
    }
  }

  assert {
    condition     = output.vulnerability_policy_slug_perms == run.creates_policies.vulnerability_policy_slug_perms
    error_message = "The vulnerability policy was replaced instead of updated."
  }

  assert {
    condition     = cloudsmith_vulnerability_policy.this["tf-module-test: critical vulnerabilities"].min_severity == "High"
    error_message = "The minimum severity did not update."
  }

  assert {
    condition     = length(cloudsmith_license_policy.this["tf-module-test: strong copyleft"].spdx_identifiers) == 3
    error_message = "The SPDX identifiers did not update."
  }
}
