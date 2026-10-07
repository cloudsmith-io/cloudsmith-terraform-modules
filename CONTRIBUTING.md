# Contributing

Please refer to Cloudsmith's standard guide on [Open-Source Contributing](https://docs.cloudsmith.com/resources/contributing).


## Contributor License Agreement

By making any contributions to Cloudsmith Ltd projects you agree to be bound by the terms of the Cloudsmith Ltd [Contributor License Agreement](https://docs.cloudsmith.com/resources/contributor-license-agreement).


## Development Environment

The tool versions are in [mise.toml](./mise.toml). Install them with [mise](https://mise.jdx.dev):

```
$ mise install
$ pre-commit install
```

The pre-commit hooks format the Terraform code, run TFLint, update the module READMEs, check the GitHub Actions workflows, and scan for typos and secrets.


## Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org), with the family as the scope:

```
feat(policy): add an EPSS threshold to the baseline
fix(policy): keep the cooldown description when importing
```

release-please uses the commit type to choose the next version of each family that a commit changes:

- `fix` makes a patch release.
- `feat` makes a minor release.
- A `!` after the type, or a `BREAKING CHANGE:` footer, makes a major release.


## Rego

Have a great idea for a new policy? Add it to [rego-recipes](https://github.com/cloudsmith-io/rego-recipes), where it gets unit tests and reaches every user of the recipes. This repository contains no Rego: the modules download each recipe at a pinned commit.


## Tests

The tests create, change and delete real Cloudsmith resources. Use a workspace that you can change freely. The [README](./README.md#run-the-tests) has the commands.

If you change the cooldown handling, run the end-to-end test in `modules/policy/tests/e2e/cooldown` too. It is the proof that a cooldown policy really hides new versions.


## Add a Module Family

A family is a group of modules that you release together, such as the policy modules. Add a family when a new best practice needs its own version and changelog.

1. Create `modules/<family>/` with the [standard module structure](https://developer.hashicorp.com/terraform/language/modules/develop/structure): a root module, a `README.md` with `<!-- BEGIN_TF_DOCS -->` and `<!-- END_TF_DOCS -->` markers, `examples/` and `tests/`. Put other modules of the family in `modules/<family>/modules/`.
2. Use relative sources, such as `../../`, only inside the family. To use a module from a different family, use its registry source and a version constraint. The mirror repository contains only the family directory.
3. Add the family to [release-please-config.json](./release-please-config.json) and [.release-please-manifest.json](./.release-please-manifest.json), with the version `0.0.0`.
4. Add the family to the table in the [README](./README.md#module-families).

A maintainer then sets up the publishing of the family once:

1. Create the public mirror repository `cloudsmith-io/terraform-cloudsmith-<family>`, with an empty first commit. Turn off issues and pull requests, and point the description to this repository.
2. Give the `MODULE_MIRROR_TOKEN` secret permission to push to the mirror repository.
3. After the first release, publish the mirror repository in the [Terraform Registry](https://registry.terraform.io/github/create), and submit it to the [OpenTofu Registry](https://github.com/opentofu/registry). Both registries then publish each new tag.


## GitHub Actions Setup

The workflows authenticate to Cloudsmith with **GitHub OIDC**. A Cloudsmith OIDC provider trusts tokens from this repository, and maps them to a service account. The workflows store no Cloudsmith API key.

| Setting | Type | Use |
| ------- | ---- | --- |
| `CLOUDSMITH_TEST_WORKSPACE` | Variable | The Cloudsmith workspace that the **Test** workflow creates resources in. |
| `CLOUDSMITH_TEST_SERVICE_SLUG` | Variable | The service account that the **Test** workflow authenticates as. |
| `CLOUDSMITH_PUBLISH_WORKSPACE` | Variable | The Cloudsmith workspace that hosts the module packages. |
| `CLOUDSMITH_PUBLISH_REPOSITORY` | Variable | The Cloudsmith repository that hosts the module packages. |
| `CLOUDSMITH_PUBLISH_SERVICE_SLUG` | Variable | The service account that the **Release** workflow authenticates as. |
| `CLOUDSMITH_BOT_PR_TOKEN` | Secret | Lets release-please open release pull requests that start the test workflows. |
| `MODULE_MIRROR_TOKEN` | Secret | Pushes releases to the mirror repositories. |

The OIDC provider of the test workspace accepts tokens from all branches of this repository. The OIDC provider of the publish workspace accepts tokens from the `main` branch only.


## Need Help?

See the section for raising a question in the [Contributing Guide](https://docs.cloudsmith.com/resources/contributing).
