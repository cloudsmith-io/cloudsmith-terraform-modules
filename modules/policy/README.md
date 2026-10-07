# Cloudsmith policy modules

Manage Cloudsmith policies, package states and tags with Terraform.

The policy package contains three modules:

| Module | Source | What it gives you |
| ------ | ------ | ----------------- |
| **policy** (this module) | `cloudsmith-io/policy/cloudsmith` | One **policy as code** policy and its actions, from any Rego source. |
| [**baseline**](modules/baseline) | `cloudsmith-io/policy/cloudsmith//modules/baseline` | The recommended secure baseline from [rego-recipes](https://github.com/cloudsmith-io/rego-recipes): a **cooldown** for new upstream versions, copyleft license tagging, high-risk vulnerability quarantine, an allowlist, a blocklist, and malware quarantine. |
| [**standard-policies**](modules/standard-policies) | `cloudsmith-io/policy/cloudsmith//modules/standard-policies` | Cloudsmith's **standard policies**: vulnerability, license and package deny policies. |

> **Policy as code** lets you write Cloudsmith policies in [Rego](https://www.openpolicyagent.org/docs/latest/policy-language/), the policy language of Open Policy Agent. Cloudsmith evaluates each policy against your packages, and applies its **actions**, such as a quarantine or a tag, to every package that matches.

The submodules share this package's version.

## Examples

| Example | Purpose |
| ------- | ------- |
| [Custom policy](examples/custom-policy) | Tag packages using the EPSS recipe. |
| [Cooldown](examples/cooldown) | Create a terminal cooldown policy directly from the upstream recipe. |
| [Recipe library](examples/recipe-library) | Create a disabled policy for each of the 19 upstream recipes, covering all categories. |
| [Baseline](examples/secure-baseline) | Configure the recommended policy order and recipe variables. |
| [Standard policies](examples/standard-policies) | Configure vulnerability, license and package deny policies without Rego. |

## Get started

1. Create an API key with permission to change the workspace settings. Policy as code needs the policy as code feature on your workspace plan.
2. Give the key to the [Cloudsmith provider](https://registry.terraform.io/providers/cloudsmith-io/cloudsmith/latest) (version 0.0.81 or later):

   ```sh
   export CLOUDSMITH_API_KEY=<api-key>
   ```

3. Add the baseline to your configuration:

   ```hcl
   module "policy_baseline" {
     source  = "cloudsmith-io/policy/cloudsmith//modules/baseline"
     version = "~> 0.1.0"

     workspace = "my-workspace"
     enabled   = false
   }
   ```

4. Run `terraform apply`, examine the new policies in the web app, and then set `enabled = true`.

## The policy module

Use this module when you want full control of the Rego, for example to use a recipe that the [baseline](modules/baseline) submodule does not include, or to write your own policy.

- Cloudsmith evaluates the **Rego** of the policy when packages are added, synchronized or copied, and when policies change.
- When the `match` rule is true for a package, Cloudsmith applies the **actions** of the policy to that package.
- An action does one thing: it sets the package state, adds tags, or removes tags.

### Usage

This example downloads the EPSS recipe from rego-recipes, and tags each package that has a vulnerability with a high **EPSS** score (the Exploit Prediction Scoring System, which estimates the probability of exploitation in the next 30 days).

```hcl
data "http" "epss_recipe" {
  url = "https://raw.githubusercontent.com/cloudsmith-io/rego-recipes/master/recipes/vulnerability/epss.rego"
}

module "exploitation_risk" {
  source  = "cloudsmith-io/policy/cloudsmith"
  version = "~> 0.1.0"

  workspace  = "my-workspace"
  name       = "Exploitation risk"
  rego       = data.http.epss_recipe.response_body
  precedence = 35

  actions = {
    tag = { add_package_tags = ["high-epss"] }
  }
}
```

Recipe downloads follow `master`, so upstream changes can appear in your next plan without a module version change. Review the Rego diff before applying. Cooldown policies restrict changes to their recipe variables; an upstream change to the policy body may require replacement.

### Write your own Rego

- Declare `package cloudsmith`.
- Write a `match` rule. Cloudsmith applies the actions when `match` is true.
- Write a `reason` set. Cloudsmith shows each reason in the **policy decision logs**, so your team can see why a package matched.

[Rego policies](https://docs.cloudsmith.com/supply-chain-security/policy-as-code/rego) describes the policy input and the supported functions.

### Evaluation order

- **Precedence** sets the order of the policies. The lowest precedence runs first.
- Cloudsmith applies the actions of all matched policies in one transaction. When two matched policies set a package state, **the last matched policy wins**.
- When a **terminal** policy (`is_terminal = true`) matches, Cloudsmith does not evaluate the policies after it.
- Actions also have a `precedence`. Set distinct values when action order matters; map keys do not determine execution order.

### Cooldown policies

An action with the `HIDDEN` state hides packages from the repository index. Only a [**cooldown policy**](https://docs.cloudsmith.com/supply-chain-security/policy-as-code/cooldown-policy) accepts a `HIDDEN` action. See the [standalone example](examples/cooldown), or use the [baseline](modules/baseline) submodule to customize its variables.

A cooldown policy has a `HIDDEN` action, is terminal, and is read only. The `is_cooldown` output is true only when all three conditions are true. For a policy with a `HIDDEN` action, the module checks the other two conditions:

- The policy must be terminal. When `is_terminal` is null, the module makes the policy terminal. If `is_terminal` is false, the plan stops.
- Cloudsmith must report the policy as read only (`read_only = true`). If not, the apply stops, because the `HIDDEN` action would have no effect.

A failed postcondition does not roll back creation: the policy may already exist in Cloudsmith and Terraform state. Correct the configuration or remove the policy through Terraform before retrying.

### Import an existing policy

```hcl
import {
  to = module.exploitation_risk.cloudsmith_policy.this
  id = "<workspace>.<policy_slug_perm>"
}

import {
  to = module.exploitation_risk.cloudsmith_policy_action.this["tag"]
  id = "<workspace>.<policy_slug_perm>.<action_slug_perm>"
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.3 |
| cloudsmith | >= 0.0.81 |

## Providers

| Name | Version |
| ---- | ------- |
| cloudsmith | >= 0.0.81 |

## Resources

| Name | Type |
| ---- | ---- |
| [cloudsmith_policy.this](https://registry.terraform.io/providers/cloudsmith-io/cloudsmith/latest/docs/resources/policy) | resource |
| [cloudsmith_policy_action.this](https://registry.terraform.io/providers/cloudsmith-io/cloudsmith/latest/docs/resources/policy_action) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| name | The name of the policy. | `string` | n/a | yes |
| rego | The Rego source of the policy. The source must declare `package cloudsmith` and a `match` rule. | `string` | n/a | yes |
| workspace | The slug of the Cloudsmith workspace that owns the policy. | `string` | n/a | yes |
| actions | The actions to apply to packages that match the policy, keyed by a stable name.<br/>Set exactly one of `set_package_state`, `add_package_tags` or `remove_package_tags` in each action. | <pre>map(object({<br/>    set_package_state   = optional(string)<br/>    add_package_tags    = optional(set(string))<br/>    remove_package_tags = optional(set(string))<br/>    precedence          = optional(number)<br/>  }))</pre> | `{}` | no |
| description | The description of the policy. Cloudsmith shows it to users when the policy blocks a package. | `string` | `null` | no |
| enabled | Set to true to evaluate the policy. | `bool` | `true` | no |
| is\_terminal | Set to true to stop the evaluation of other policies when this policy matches. When null, the policy is terminal only if it has a HIDDEN action. | `bool` | `null` | no |
| precedence | The evaluation order of the policy relative to other policies in the workspace. Cloudsmith assigns a value when it is null. | `number` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| action\_slug\_perms | The permanent slugs of the policy actions, keyed by action name. |
| is\_cooldown | True when the policy is a cooldown policy: it has a HIDDEN action, is terminal, and is read only. |
| name | The name of the policy. |
| precedence | The precedence of the policy. |
| read\_only | True when Cloudsmith marks the policy as read only. You can then change only the cooldown variables in the Rego. |
| slug\_perm | The permanent slug of the policy. |
| version | The version of the Rego source. Cloudsmith increments it when the Rego changes. The provider does not show the new value until the next plan. |
<!-- END_TF_DOCS -->
