# Upstream package cooldown

Downloads [publish_date_cooldown.rego from master](https://raw.githubusercontent.com/cloudsmith-io/rego-recipes/master/recipes/date-time/publish_date_cooldown.rego) and passes it directly to the policy module. The policy is terminal and has a `HIDDEN` action, as required by Cloudsmith.

Set `CLOUDSMITH_API_KEY`, then run from this directory:

```sh
terraform init
terraform apply -var='workspace=my-workspace'
```

The policy starts disabled. Review it in Cloudsmith before enabling it:

```sh
terraform apply -var='workspace=my-workspace' -var='enabled=true'
```

The recipe supplies the cooldown window, formats and repository scope. Use the [baseline submodule](../../modules/baseline) to customize those values with Terraform inputs. Do not apply this example alongside another cooldown policy in the same workspace; import an existing policy and its action instead.

Because the recipe follows `master`, review upstream changes in the plan. Changes to the cooldown body, rather than just its variables, may require replacing the policy.

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
| cooldown | ../../ | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [http_http.recipe](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| workspace | The slug of the Cloudsmith workspace. | `string` | n/a | yes |
| enabled | Enable the cooldown after reviewing it in Cloudsmith. | `bool` | `false` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| policy | The cooldown policy identity and recognition status. |
<!-- END_TF_DOCS -->
