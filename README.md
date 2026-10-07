# Cloudsmith Terraform modules

Terraform modules for managing Cloudsmith infrastructure as code.

## Modules

| Package | Purpose |
| ------- | ------- |
| [policy](modules/policy) | Policy as code, a security baseline, and standard vulnerability, license and package deny policies. |

Each package's README contains its usage, submodules, examples and requirements.

## Registries

| Registry | Policy module source |
| -------- | -------------------- |
| [Terraform Registry](https://registry.terraform.io/namespaces/cloudsmith-io) | `cloudsmith-io/policy/cloudsmith` |
| [OpenTofu Registry](https://search.opentofu.org) | `cloudsmith-io/policy/cloudsmith` |
| [Cloudsmith](https://app.cloudsmith.com/cloudsmith/repos/terraform-modules/packages/) | `terraform.cloudsmith.io/terraform-modules/policy/cloudsmith` |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, tests, releases and adding modules. Make changes in this repository, not the registry mirror repositories.

## License

Copyright 2026 Cloudsmith Ltd

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
