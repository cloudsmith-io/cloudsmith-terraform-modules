# Cloudsmith Terraform modules

Put Cloudsmith best practices into your infrastructure as code. Each module family in this repository packages a proven way to configure Cloudsmith, such as a secure policy baseline. Your team can then use a few lines of Terraform instead of many hours of setup.

## Module families

| Family | Registry source | What it gives you |
| ------ | --------------- | ----------------- |
| [**policy**](modules/policy) | `cloudsmith-io/policy/cloudsmith` | Policy as code, the secure baseline from [rego-recipes](https://github.com/cloudsmith-io/rego-recipes) with a tested **cooldown** policy, and the standard vulnerability, license and deny policies. |

More families are on the way. Each family has its own version and changelog, so you can upgrade one without the others.

## Where to get the modules

Every release goes to three places. Use the one that suits your organization:

| Registry | Source address |
| -------- | -------------- |
| [Terraform Registry](https://registry.terraform.io/namespaces/cloudsmith-io) | `cloudsmith-io/<family>/cloudsmith` |
| [OpenTofu Registry](https://search.opentofu.org) | `cloudsmith-io/<family>/cloudsmith` |
| Cloudsmith | `terraform.cloudsmith.io/<repository>/<family>/cloudsmith` |

> **Tip:** Install the modules through Cloudsmith, and get the same control over your Terraform modules as over all your other packages.

## Repository layout

This repository is the development home of all the families. Each family is one directory under `modules/`, with the [standard module structure](https://developer.hashicorp.com/terraform/language/modules/develop/structure):

```
modules/
  <family>/
    main.tf, variables.tf, outputs.tf, versions.tf   The root module of the family
    README.md                                        The registry page of the family
    CHANGELOG.md                                     Written by release-please
    modules/<submodule>/                             Submodules, each with a README and tests
    examples/<example>/                              Configurations that users can copy
    tests/                                           terraform test files
```

The Terraform and OpenTofu registries need one GitHub repository for each module. The release workflow therefore copies each released family to a read-only **mirror repository**, `cloudsmith-io/terraform-cloudsmith-<family>`. Do not change a mirror directly: make all changes here.

## Development

Install the tools with [mise](https://mise.jdx.dev), and install the Git hooks:

```sh
mise install
pre-commit install
```

The **pre-commit hooks** format the Terraform code, run TFLint, update the module READMEs, check the GitHub Actions workflows, and scan for typos and secrets.

### Run the tests

The tests create, change and delete real Cloudsmith resources, so use a workspace that you can change freely.

```sh
export CLOUDSMITH_API_KEY=<api-key>
export TF_VAR_workspace=<workspace>

terraform -chdir=modules/policy/modules/baseline init
terraform -chdir=modules/policy/modules/baseline test
```

`terraform test` runs the test files in a directory and in its `tests` subdirectory. The **Test** workflow finds every such directory and runs the tests:

- On each push to `main` and each pull request from this repository.
- Every day, because Cloudsmith can change without a commit here.

The workflow authenticates to Cloudsmith with GitHub OIDC, so it needs no stored API key. Pull requests from forks cannot get an OIDC token, so the workflow skips the tests for them.

### Update the documentation

The input and output tables in the module READMEs come from the code. The pre-commit hooks update them, or you can run:

```sh
terraform-docs -c .terraform-docs.yml <module-directory>
```

## Releases

[release-please](https://github.com/googleapis/release-please) reads the [Conventional Commits](https://www.conventionalcommits.org) on `main`, and opens one release pull request for each family that changed. When you merge a release pull request:

1. release-please tags the release, for example `policy-v1.2.0`, and updates the changelog of the family.
2. The **Release** workflow pushes the family to its mirror repository with the tag `v1.2.0`. The Terraform and OpenTofu registries publish the new tag.
3. The workflow uploads the family to Cloudsmith as `terraform-cloudsmith-<family>-1.2.0.tar.gz`.

[CONTRIBUTING.md](CONTRIBUTING.md) explains how to add a family and how to set up its publishing.

## Contributing

We welcome contributions! Read [CONTRIBUTING.md](CONTRIBUTING.md) to get started.

## License

Copyright 2026 Cloudsmith Ltd

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
