# Cloudsmith policy modules

Manage your Cloudsmith policies as code. Review each change in a pull request, and give every workspace the same strong defense.

This module family has three parts:

| Module | Source | What it gives you |
| ------ | ------ | ----------------- |
| **policy** (this module) | `cloudsmith-io/policy/cloudsmith` | One **policy as code** policy and its actions, from any Rego source. |
| [**baseline**](modules/baseline) | `cloudsmith-io/policy/cloudsmith//modules/baseline` | The recommended secure baseline from [rego-recipes](https://github.com/cloudsmith-io/rego-recipes): a **cooldown** for new upstream versions, copyleft license tagging, high-risk vulnerability quarantine, an allowlist, a blocklist, and malware quarantine. |
| [**standard-policies**](modules/standard-policies) | `cloudsmith-io/policy/cloudsmith//modules/standard-policies` | Cloudsmith's **standard policies**: vulnerability, license and package deny policies. |

> **Policy as code** lets you write Cloudsmith policies in [Rego](https://www.openpolicyagent.org/docs/latest/policy-language/), the policy language of Open Policy Agent. Cloudsmith evaluates each policy against your packages, and applies its **actions**, such as a quarantine or a tag, to every package that matches.

The [examples](examples) directory has a ready-to-run configuration for each module.

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
     version = "~> 0.1"

     workspace = "my-workspace"
     enabled   = false
   }
   ```

4. Run `terraform apply`, examine the new policies in the web app, and then set `enabled = true`.

**Tip:** The modules are also in the [OpenTofu Registry](https://search.opentofu.org) with the same source address, and in Cloudsmith. To install from Cloudsmith, use `source = "terraform.cloudsmith.io/<repository>/policy/cloudsmith"`.

## The policy module

Use this module when you want full control of the Rego, for example to use a recipe that the [baseline](modules/baseline) submodule does not include, or to write your own policy.

- Cloudsmith evaluates the **Rego** of the policy when packages are added, synchronized or copied, and when policies change.
- When the `match` rule is true for a package, Cloudsmith applies the **actions** of the policy to that package.
- An action does one thing: it sets the package state, adds tags, or removes tags.

### Usage

This example downloads the EPSS recipe from rego-recipes, and tags each package that has a vulnerability with a high **EPSS** score (the Exploit Prediction Scoring System, which estimates the probability of exploitation in the next 30 days).

```hcl
data "http" "epss_recipe" {
  url = "https://raw.githubusercontent.com/cloudsmith-io/rego-recipes/<commit>/recipes/vulnerability/epss.rego"
}

module "exploitation_risk" {
  source  = "cloudsmith-io/policy/cloudsmith"
  version = "~> 0.1"

  workspace  = "my-workspace"
  name       = "Exploitation risk"
  rego       = data.http.epss_recipe.response_body
  precedence = 35

  actions = {
    tag = { add_package_tags = ["high-epss"] }
  }
}
```

**Tip:** Start with a recipe from [rego-recipes](https://github.com/cloudsmith-io/rego-recipes). Each recipe has unit tests, so you start from a policy that is known to work.

### Write your own Rego

- Declare `package cloudsmith`.
- Write a `match` rule. Cloudsmith applies the actions when `match` is true.
- Write a `reason` set. Cloudsmith shows each reason in the **policy decision logs**, so your team can see why a package matched.

[Rego policies](https://docs.cloudsmith.com/supply-chain-security/policy-as-code/rego) describes the policy input and the supported functions.

### Evaluation order

- **Precedence** sets the order of the policies. The lowest precedence runs first.
- Cloudsmith applies the actions of all matched policies in one transaction. When two matched policies set a package state, **the last matched policy wins**.
- When a **terminal** policy (`is_terminal = true`) matches, Cloudsmith does not evaluate the policies after it.

### Cooldown policies

An action with the `HIDDEN` state hides packages from the repository index. Only a [**cooldown policy**](https://docs.cloudsmith.com/supply-chain-security/policy-as-code/cooldown-policy) accepts a `HIDDEN` action. Use the [baseline](modules/baseline) submodule to create one.

For a policy with a `HIDDEN` action, the module protects you in two ways:

- **Before the apply**, it makes sure that `is_terminal` is true. Cloudsmith rejects a cooldown policy that is not terminal.
- **After the apply**, it makes sure that Cloudsmith accepted the policy as a cooldown policy (`read_only = true`). If not, the apply stops, because the `HIDDEN` action would have no effect.

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

## How the tests prove the cooldown works

The **cooldown policy** hides new upstream versions until they reach a minimum age. It gives the security community time to find a malicious release before your builds can download it. Cloudsmith only treats a policy as a cooldown policy when the policy has the correct shape. The tests make sure that it does, every time:

- **Every supported format.** A test changes one cooldown policy to each supported format in turn. Cloudsmith must report `read_only = true` for each one.
- **A safety net for bad changes.** A test changes a working cooldown policy to an unsupported format. The module must stop the apply.
- **A real index.** The end-to-end test in `tests/e2e/cooldown` creates a private repository with a PyPI upstream. It then shows that the cooldown hides `six` 1.17.0 from the index and blocks its download, while `six` 1.16.0 stays available.

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
| is\_terminal | Set to true to stop the evaluation of other policies when this policy matches. | `bool` | `false` | no |
| precedence | The evaluation order of the policy relative to other policies in the workspace. Cloudsmith assigns a value when it is null. | `number` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| action\_slug\_perms | The permanent slugs of the policy actions, keyed by action name. |
| name | The name of the policy. |
| precedence | The precedence of the policy. |
| read\_only | True when Cloudsmith accepts the policy as a cooldown policy. You can then change only the cooldown variables in the Rego. |
| slug\_perm | The permanent slug of the policy. |
| version | The version of the Rego source. Cloudsmith increments it when the Rego changes. The provider does not show the new value until the next plan. |
<!-- END_TF_DOCS -->
