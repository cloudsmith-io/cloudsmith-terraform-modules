# Cloudsmith Terraform modules

Terraform modules for managing Cloudsmith. The first release covers policies; other Cloudsmith modules will be added here with their own versions and changelogs.

## Modules

| Module | Registry source | Purpose |
| ------ | --------------- | ------- |
| [policy](modules/policy) | `cloudsmith-io/policy/cloudsmith` | A policy as code policy and its actions, using your own Rego source. |
| [baseline](modules/policy/modules/baseline) | `cloudsmith-io/policy/cloudsmith//modules/baseline` | Cooldown, license tagging, vulnerability quarantine, allowlists, blocklists and malware quarantine from [rego-recipes](https://github.com/cloudsmith-io/rego-recipes). |
| [standard-policies](modules/policy/modules/standard-policies) | `cloudsmith-io/policy/cloudsmith//modules/standard-policies` | Standard vulnerability, license and package deny policies. |

`policy` is the published module name. `baseline` and `standard-policies` are submodules of that package and share its version.

## Usage

```hcl
module "policy_baseline" {
  source  = "cloudsmith-io/policy/cloudsmith//modules/baseline"
  version = "~> 0.1.0"

  workspace = "my-workspace"
  enabled   = false
}
```

Configure the [Cloudsmith provider](https://registry.terraform.io/providers/cloudsmith-io/cloudsmith/latest) with `CLOUDSMITH_API_KEY`. Apply with policies disabled, review them in Cloudsmith, then set `enabled = true`. See the [module documentation](modules/policy) for requirements, configuration and imports.

## Registries

| Registry | Policy module source |
| -------- | -------------------- |
| [Terraform Registry](https://registry.terraform.io/namespaces/cloudsmith-io) | `cloudsmith-io/policy/cloudsmith` |
| [OpenTofu Registry](https://search.opentofu.org) | `cloudsmith-io/policy/cloudsmith` |
| [Cloudsmith](https://app.cloudsmith.com/cloudsmith/repos/terraform-modules/packages/) | `terraform.cloudsmith.io/terraform-modules/policy/cloudsmith` |

To install from Cloudsmith, configure credentials in your **local** `~/.terraformrc` (or `terraform.rc` on Windows):

```hcl
credentials "terraform.cloudsmith.io" {
  token = "cloudsmith/terraform-modules/<entitlement-token>"
}
```

The workspace (`cloudsmith`) belongs in the credentials token, not the module source address. The repository is `terraform-modules`. These download credentials are separate from the provider's `CLOUDSMITH_API_KEY`; never commit either credential. See [Cloudsmith's registry documentation](https://docs.cloudsmith.com/formats/terraform-modules-repository).

For the baseline, append `//modules/baseline` to the Cloudsmith source address.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, tests, releases and adding modules. Make changes in this repository, not the registry mirror repositories.

## License

Copyright 2026 Cloudsmith Ltd

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
