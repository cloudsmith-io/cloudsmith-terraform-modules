# Recipe library

Creates a separate, **disabled** policy for each of the 19 recipes in [rego-recipes](https://github.com/cloudsmith-io/rego-recipes). Files are downloaded from `master` rather than copied into this repository.

This is a catalog of independent examples, not a recommended combination of policies. Each non-cooldown policy tags matches with `recipe-<filename>` so you can inspect its decisions without changing package availability. The cooldown has the required terminal flag and `HIDDEN` action. Review each recipe's variables and choose appropriate actions before enabling it.

| Category | Recipes | What they match |
| -------- | ------- | --------------- |
| Date/time | `publish_date_cooldown`, `upload_date` | Newly published versions; uploads during a change freeze. |
| Format/name/version | `allowlist`, `blocklist`, `format_filename_pattern`, `minimum_version`, `repo_filename_contains` | Explicit package lists, naming violations, old versions and debug artifacts. |
| Hugging Face | `model_card`, `risky_files`, `security_scan`, `trusted_publishers` | Blocked training datasets, risky files, unsafe scans and verified publishers. |
| License | `copyleft_licenses` | Copyleft licenses on packages or SBOM components. |
| Metadata | `architecture`, `tags` | Disallowed architectures, deprecated tags or excessive tag counts. |
| Vulnerability | `best_cvss_with_fix`, `cvss_with_fix`, `epss`, `id_blocklist`, `malware` | Fixable vulnerabilities, exploitation risk, blocked vulnerability IDs and malware. |

The allowlist and trusted-publisher recipes match approved packages; their tag actions are intentional. They must not be treated as quarantine rules. Dates, package lists, publisher lists and thresholds come from the upstream examples and need review for your workspace.

Set `CLOUDSMITH_API_KEY`, then run from this directory:

```sh
terraform init
terraform plan -var='workspace=my-workspace'
terraform apply -var='workspace=my-workspace'
```

Use a test workspace without an existing cooldown policy. Even a disabled cooldown counts toward the one-cooldown-per-workspace limit. The [standalone cooldown example](../cooldown) shows only that recipe; the [baseline](../secure-baseline) shows an ordered set of enforcement policies.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.15 |
| cloudsmith | >= 0.0.81 |
| http | >= 3.4 |

## Providers

| Name | Version |
| ---- | ------- |
| http | >= 3.4 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| recipe | ../../ | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [http_http.recipe](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| workspace | The slug of the Cloudsmith workspace. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| policies | The disabled policies, keyed by recipe path. |
<!-- END_TF_DOCS -->
