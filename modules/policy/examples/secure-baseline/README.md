# Policy baseline

Creates the baseline with a seven-day cooldown for npm and Python, a CVSS threshold of 8.0, and example allowlist and blocklist entries. Replace the example entries and repository exclusion with your own values.

Set `CLOUDSMITH_API_KEY`, then run from this directory:

```sh
terraform init
terraform plan -var='workspace=my-workspace'
terraform apply -var='workspace=my-workspace'
```

The policies are enabled immediately and can hide or quarantine packages. Set `enabled = false` on the module to review them first. The workspace must not already have a cooldown policy unless you import it as described in the [baseline documentation](../../modules/baseline).

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.3 |
| cloudsmith | >= 0.0.81 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| policy\_baseline | ../../modules/baseline | n/a |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| workspace | The slug of the Cloudsmith workspace. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| policies | n/a |
<!-- END_TF_DOCS -->
