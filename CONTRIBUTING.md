# Contributing

Please refer to Cloudsmith's standard guide on [Open-Source Contributing](https://docs.cloudsmith.com/resources/contributing).


## Contributor License Agreement

By making any contributions to Cloudsmith Ltd projects you agree to be bound by the terms of the Cloudsmith Ltd [Contributor License Agreement](https://docs.cloudsmith.com/resources/contributor-license-agreement).


## Development Environment

The tool versions are in [mise.toml](./mise.toml). Install them with [mise](https://mise.jdx.dev):

```
$ mise install
$ uv sync --locked
$ pre-commit install
```

Run `pre-commit run --all-files` before submitting a change. The hooks format and validate Terraform, run TFLint and Ruff, update module READMEs, check GitHub Actions, and scan for typos and secrets. Activate mise in your shell or prefix commands with `mise exec --`.

The README input and output tables are generated with [terraform-docs](https://terraform-docs.io). To update one module:

```sh
terraform-docs -c .terraform-docs.yml modules/policy
```


## Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org), with the published module name as the scope:

```
feat(policy): add an EPSS threshold to the baseline
fix(policy): keep the cooldown description when importing
```

release-please uses the commit type to choose the next version of each module package that a commit changes:

- `fix` makes a patch release.
- `feat` makes a minor release.
- A `!` after the type, or a `BREAKING CHANGE:` footer, makes a major release.


## Rego

Have a great idea for a new policy? Add it to [rego-recipes](https://github.com/cloudsmith-io/rego-recipes), where it gets unit tests and reaches every user of the recipes. The baseline and examples download recipes from `master`; they do not maintain their own copies. Review resulting plan changes when upstream recipes change.


## Tests

The Terraform unit tests in `tests/unit` mock Cloudsmith and cover input validation and recipe rendering. They do not need credentials, although baseline tests download public recipes. Run them with Terraform 1.15 or later:

```sh
terraform -chdir=modules/policy init -backend=false
terraform -chdir=modules/policy test -test-directory=tests/unit
```

Run the same commands in `modules/policy/modules/baseline` and `modules/policy/modules/standard-policies`.

Python unit tests cover the HTTP probe's cache busting, retries and visibility checks:

```sh
uv run --locked pytest -m 'not integration'
```

The integration tests create, change and delete real resources. Use a disposable Cloudsmith workspace with no existing cooldown policy, and do not run suites concurrently against it:

```sh
export CLOUDSMITH_API_KEY='<api-key>'
export TF_VAR_workspace='<workspace>'

terraform -chdir=modules/policy/modules/baseline init
terraform -chdir=modules/policy/modules/baseline test
```

Run Terraform integration tests in `modules/policy`, both submodules, and the `cooldown` and `recipe-library` examples. These check resource creation, updates, API readback and acceptance of the upstream recipes without repeating unit validation cases.

Then run the pytest integration suite with the same credentials:

```sh
uv run --locked pytest -m integration
```

It checks all eight supported cooldown formats, then verifies that enabling and shortening a cooldown changes actual PyPI index visibility and wheel download status. It uses the Terraform fixture in `modules/policy/tests/e2e/cooldown`, isolated state in pytest's temporary directory, and teardown that destroys resources even after a failed assertion or apply. HTTP requests carry a fresh `request_id` to bypass the CDN cache. If the process is forcibly stopped or teardown fails, use the retained temporary state to destroy the resources before rerunning.

CI runs lint, validation and unit tests on all pull requests, including forks. Integration tests run on pushes to `main`, same-repository pull requests other than Dependabot's, manual dispatch and a daily schedule, using the test workspace's API key.


## Releases

Each top-level module package has its own version and changelog. Its submodules are released with it; `policy`, `policy//modules/baseline` and `policy//modules/standard-policies` share one version.

[release-please](https://github.com/googleapis/release-please) opens a release pull request for each changed package. The pull request also changes the version in the module source URLs of the READMEs. Merging it creates a tag such as `policy-v0.1.0`. The release workflow publishes that tagged source to the `cloudsmith/terraform-modules` Cloudsmith repository, as `terraform-cloudsmith-policy-0.1.0.tar.gz`.

The workflow also has a job that publishes to the `cloudsmith-io/terraform-cloudsmith-policy` mirror for the Terraform and OpenTofu registries. The job is disabled until the mirror exists.

Dependabot opens grouped workflow updates for review. They use the same review and merge process as other changes.


## Add a Module

Use a new top-level directory when a module needs an independent release cycle. Use a submodule for a related capability that should share an existing package's version.

1. Create `modules/<name>/` using the [standard module structure](https://developer.hashicorp.com/terraform/language/modules/develop/structure): `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, a README, examples and tests. Put related submodules under `modules/<name>/modules/`.
2. Keep provider configuration in the caller or example, not inside reusable modules. Declare minimum supported Terraform and provider versions, and use typed inputs and documented outputs.
3. Use relative sources only within a package. References to another top-level package must use its registry source and a version constraint, because each registry archive contains only one package.
4. Add `<!-- BEGIN_TF_DOCS -->` and `<!-- END_TF_DOCS -->` markers to each module README. Include a runnable example and tests for defaults, optional resources and invalid inputs.
5. Register the package in [release-please-config.json](./release-please-config.json) and [.release-please-manifest.json](./.release-please-manifest.json), starting at `0.0.0`. Add it to the [module table](./README.md#modules).

Before its first release, a maintainer must create the public `cloudsmith-io/terraform-cloudsmith-<name>` mirror with an initial commit and grant the publishing token write access. Disable issues in the mirror and direct contributions here. Register the mirror with the [Terraform Registry](https://registry.terraform.io/github/create) and [OpenTofu Registry](https://github.com/opentofu/registry) after the first tag.


## Need Help?

See the section for raising a question in the [Contributing Guide](https://docs.cloudsmith.com/resources/contributing).
