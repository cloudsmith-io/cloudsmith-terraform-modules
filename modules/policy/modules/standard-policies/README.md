# standard-policies

Manage Cloudsmith's [standard vulnerability, license and package deny policies](https://docs.cloudsmith.com/policy-management) without writing Rego.

| Policy type | What it does |
| ----------- | ------------ |
| **Vulnerability policy** | Flags or quarantines packages with a vulnerability at or above a severity. |
| **License policy** | Flags or quarantines packages with a license that you do not allow. |
| **Package deny policy** | Blocks the download of packages that match a search query. |

Each map key is the policy name. For more control, use the [policy](../../) module and the [baseline](../baseline) submodule for policy as code.

## Usage

```hcl
module "standard_policies" {
  source  = "cloudsmith-io/policy/cloudsmith//modules/standard-policies"
  version = "~> 0.1.0"

  workspace = "my-workspace"

  vulnerability_policies = {
    "Critical vulnerabilities" = {
      min_severity            = "Critical"
      on_violation_quarantine = true
      package_query_string    = "format:python"
    }
  }

  license_policies = {
    "Strong copyleft" = {
      description      = "Packages with a strong copyleft license."
      spdx_identifiers = ["AGPL-3.0-only", "GPL-3.0-only"]
    }
  }

  deny_policies = {
    "Compromised versions" = {
      package_query = "format:npm AND name:^example-ui$ AND version:4.5.6"
    }
  }
}
```

## Good to know

- `min_severity` is one of `Low`, `Medium`, `High` and `Critical`.
- `spdx_identifiers` takes **SPDX** license identifiers, the standard short names for licenses, such as `Apache-2.0`.
- `package_query` and `package_query_string` use the [package search syntax](https://docs.cloudsmith.com/artifact-management/search-filter-sort-packages). A deny policy query has a maximum of 256 characters.
- The map key is the policy name, so Terraform replaces a policy when you rename it.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.3 |
| cloudsmith | >= 0.0.81 |

## Providers

| Name | Version |
| ---- | ------- |
| cloudsmith | >= 0.0.81 |

## Resources

| Name | Type |
| ---- | ---- |
| [cloudsmith_license_policy.this](https://registry.terraform.io/providers/cloudsmith-io/cloudsmith/latest/docs/resources/license_policy) | resource |
| [cloudsmith_package_deny_policy.this](https://registry.terraform.io/providers/cloudsmith-io/cloudsmith/latest/docs/resources/package_deny_policy) | resource |
| [cloudsmith_vulnerability_policy.this](https://registry.terraform.io/providers/cloudsmith-io/cloudsmith/latest/docs/resources/vulnerability_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| workspace | The slug of the Cloudsmith workspace that owns the policies. | `string` | n/a | yes |
| deny\_policies | The package deny policies, keyed by policy name. Cloudsmith blocks the download of packages that match `package_query`. | <pre>map(object({<br/>    description   = optional(string)<br/>    package_query = string<br/>    enabled       = optional(bool, true)<br/>  }))</pre> | `{}` | no |
| license\_policies | The license policies, keyed by policy name. Cloudsmith flags packages with a license in `spdx_identifiers`. | <pre>map(object({<br/>    description             = string<br/>    spdx_identifiers        = set(string)<br/>    on_violation_quarantine = optional(bool, false)<br/>    allow_unknown_licenses  = optional(bool, false)<br/>    package_query_string    = optional(string)<br/>  }))</pre> | `{}` | no |
| vulnerability\_policies | The vulnerability policies, keyed by policy name. Cloudsmith flags packages with a vulnerability at or above `min_severity`. | <pre>map(object({<br/>    description             = optional(string)<br/>    min_severity            = optional(string, "Critical")<br/>    on_violation_quarantine = optional(bool, false)<br/>    allow_unknown_severity  = optional(bool, false)<br/>    package_query_string    = optional(string)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| deny\_policy\_ids | The IDs of the package deny policies, keyed by policy name. |
| license\_policy\_slug\_perms | The permanent slugs of the license policies, keyed by policy name. |
| vulnerability\_policy\_slug\_perms | The permanent slugs of the vulnerability policies, keyed by policy name. |
<!-- END_TF_DOCS -->
