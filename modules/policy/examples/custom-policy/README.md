# Custom policy

Downloads the pinned EPSS recipe and tags matching packages with `high-epss`.

Set `CLOUDSMITH_API_KEY`, then run from this directory:

```sh
terraform init
terraform plan -var='workspace=my-workspace'
terraform apply -var='workspace=my-workspace'
```

The policy is enabled immediately. Use a test workspace or set `enabled = false` on the module before applying.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.3 |
| cloudsmith | >= 0.0.81 |
| http | >= 3.4 |

## Providers

| Name | Version |
| ---- | ------- |
| http | >= 3.4 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| exploitation\_risk | ../../ | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [http_http.epss_recipe](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| workspace | The slug of the Cloudsmith workspace. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| slug\_perm | n/a |
<!-- END_TF_DOCS -->
