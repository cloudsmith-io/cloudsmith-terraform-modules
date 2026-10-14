# Standard policies

Creates a critical-vulnerability policy for Python packages, a copyleft license policy, and a package deny policy. The first two quarantine matching packages; the deny policy blocks matching downloads. Replace the example license identifiers and package query as needed.

Set `CLOUDSMITH_API_KEY`, then run from this directory:

```sh
terraform init
terraform plan -var='workspace=my-workspace'
terraform apply -var='workspace=my-workspace'
```

These policies take effect immediately. Use a test workspace when trying the example.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.15 |
| cloudsmith | >= 0.0.81 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| standard\_policies | ../../modules/standard-policies | n/a |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| workspace | The slug of the Cloudsmith workspace. | `string` | n/a | yes |
<!-- END_TF_DOCS -->
