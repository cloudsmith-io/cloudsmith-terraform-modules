# baseline

The **baseline** submodule configures policies from [rego-recipes](https://github.com/cloudsmith-io/rego-recipes): cooldown for new upstream releases, copyleft license tagging, vulnerability and malware quarantine, and package allowlists and blocklists.

## The baseline

| Key | Recipe | What it does | Default precedence | Default action |
| --- | ------ | ------------ | ------------------ | -------------- |
| `cooldown` | [`publish_date_cooldown.rego`](https://raw.githubusercontent.com/cloudsmith-io/rego-recipes/master/recipes/date-time/publish_date_cooldown.rego) | Hides new upstream versions until they reach a minimum age | 10 | Set the state to `HIDDEN` |
| `copyleft_licenses` | [`copyleft_licenses.rego`](https://raw.githubusercontent.com/cloudsmith-io/rego-recipes/master/recipes/license/copyleft_licenses.rego) | Finds **copyleft** licenses, which require derived work to use the same license | 20 | Add the tag `copyleft-license` |
| `high_risk_vulnerabilities` | [`cvss_with_fix.rego`](https://raw.githubusercontent.com/cloudsmith-io/rego-recipes/master/recipes/vulnerability/cvss_with_fix.rego) | Finds vulnerabilities with a high **CVSS** score (Common Vulnerability Scoring System) that have a fix | 30 | Set the state to `QUARANTINED` |
| `allowlist` | [`allowlist.rego`](https://raw.githubusercontent.com/cloudsmith-io/rego-recipes/master/recipes/format-name-version/allowlist.rego) | Approves exact package versions | 40 | Set the state to `AVAILABLE` |
| `blocklist` | [`blocklist.rego`](https://raw.githubusercontent.com/cloudsmith-io/rego-recipes/master/recipes/format-name-version/blocklist.rego) | Blocks packages or exact versions | 50 | Set the state to `QUARANTINED` |
| `malware` | [`malware.rego`](https://raw.githubusercontent.com/cloudsmith-io/rego-recipes/master/recipes/vulnerability/malware.rego) | Finds known malicious packages | 60 | Set the state to `QUARANTINED` |

The module creates all the policies by default. To leave a policy out, set its variable to `null`. The module creates the allowlist and blocklist policies only when you give entries.

## Why the order matters

Cloudsmith evaluates the policies from the lowest precedence to the highest, and **the last matched state wins**. The default order gives you the result you expect:

```mermaid
flowchart LR
    A[Cooldown<br/>10] --> B[Copyleft licenses<br/>20] --> C[High-risk vulnerabilities<br/>30] --> D[Allowlist<br/>40] --> E[Blocklist<br/>50] --> F[Malware<br/>60]
```

- The **allowlist** makes an approved package available again after the vulnerability policy quarantines it.
- The **blocklist** and **malware** policies come last within this baseline, so its allowlist cannot override them. Other workspace policies with higher precedence can still change the result.

The cooldown is terminal: when it matches, later policies are not evaluated. A package inside the cooldown window is hidden, not also tagged or quarantined by the rest of this baseline.

## Usage

```hcl
module "policy_baseline" {
  source  = "cloudsmith-io/policy/cloudsmith//modules/baseline"
  version = "~> 0.1.0"

  workspace = "my-workspace"

  cooldown = {
    within_past_days  = 7
    supported_formats = ["npm", "python"]
  }

  allowlist = { entries = ["python:example-lib:1.2.3"] }
  blocklist = { entries = ["npm:compromised-ui"] }
}
```

Set `enabled = false` for the first apply to review the policies before they affect packages.

## Tune a recipe

Each recipe has variables, such as `within_past_days` in the cooldown recipe. Set an attribute to change the variable. Leave it `null` to keep the value from the recipe. The module changes only the variables that you set, and takes the policy name and description from the METADATA block of the recipe.

`cooldown.include_local_packages` defaults to `true` in the recipe. Set it to `false` to exclude locally uploaded packages. A package still needs an upstream publish date to match the cooldown, even when local packages are included.

## Recipe downloads

- Terraform downloads the recipes with the [http provider](https://registry.terraform.io/providers/hashicorp/http/latest) during each plan.
- The Terraform runner needs network access to `raw.githubusercontent.com`, or to the mirror specified by `recipes_url`.
- `recipes_ref` defaults to `master`. Recipe updates can change the next plan without a module version change; review the rendered Rego diff before applying.
- Set `recipes_url` to use a mirror of the repository. It must serve the same files at `/<recipes_ref>/recipes/<path>`.
- The plan stops if a download fails, or if a recipe does not define a variable that you set.

## Cooldown policy

The [cooldown policy](https://docs.cloudsmith.com/supply-chain-security/policy-as-code/cooldown-policy) hides new versions of upstream packages from the repository index until they reach the minimum age. If a client asks for a hidden version, Cloudsmith returns HTTP 403 with the policy name and description. Set `cooldown.description` to tell your developers what to do next, for example who to ask for an exemption.

### Rules from Cloudsmith

- After Cloudsmith creates the policy, you can change only the name, the description, the enabled state, and the values of the cooldown variables: `within_past_days`, `supported_formats`, `included_repositories`, `excluded_repositories` and `include_local_packages`.
- The policy must be **terminal**.
- A workspace can have only one cooldown policy.
- A cooldown policy without a `HIDDEN` action matches packages, but does not hide them.
- The cooldown applies only to packages that have an upstream publish date.
- Clients can see the old index for a short time after a change, because of caching. Changes can take some minutes to reach cached packages.

### Checks in the module

- `supported_formats` must contain one or more of the supported formats: `cargo`, `conda`, `docker`, `go`, `maven`, `npm`, `nuget` and `python`. An empty set matches no packages.
- `within_past_days` must be a whole number of 1 or more.
- After the apply, Cloudsmith must report the policy as a cooldown policy (`read_only = true`). If not, the apply stops.

The format tests check API recognition for all eight formats; end-to-end index and download enforcement is tested for Python.

### Changes to the cooldown recipe

If upstream changes the cooldown recipe in more than its variables, Cloudsmith rejects the update. Replace the policy:

```sh
terraform apply -replace='module.policy_baseline.module.policy["cooldown"].cloudsmith_policy.this'
```

### Import a cooldown policy from the web app

When you create a cooldown policy from the web app template, Cloudsmith also creates its `HIDDEN` action. Import both before the first apply. If you do not, the apply stops, because a workspace can have only one cooldown policy.

```hcl
import {
  to = module.policy_baseline.module.policy["cooldown"].cloudsmith_policy.this
  id = "<workspace>.<policy_slug_perm>"
}

import {
  to = module.policy_baseline.module.policy["cooldown"].cloudsmith_policy_action.this["hide"]
  id = "<workspace>.<policy_slug_perm>.<action_slug_perm>"
}
```

Set `cooldown.name` and `cooldown.description` to the values in the web app, or Terraform changes them.

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
| policy | ../../ | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [http_http.recipe](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| workspace | The slug of the Cloudsmith workspace that owns the policies. | `string` | n/a | yes |
| allowlist | The allowlist policy matches packages in `entries`, in the format `format:name:version`.<br/>The default action makes the packages available again, after the policies with a lower precedence quarantine them.<br/>The module creates the policy only when `entries` is not empty. Set to null to omit it. | <pre>object({<br/>    entries     = optional(set(string), [])<br/>    precedence  = optional(number, 40)<br/>    name        = optional(string)<br/>    description = optional(string)<br/>    enabled     = optional(bool)<br/>    actions = optional(map(object({<br/>      set_package_state   = optional(string)<br/>      add_package_tags    = optional(set(string))<br/>      remove_package_tags = optional(set(string))<br/>      precedence          = optional(number)<br/>    })), { allow = { set_package_state = "AVAILABLE" } })<br/>  })</pre> | `{}` | no |
| blocklist | The blocklist policy matches packages in `entries`, in the format `format:name` or `format:name:version`.<br/>The module creates the policy only when `entries` is not empty. Set to null to omit it. | <pre>object({<br/>    entries     = optional(set(string), [])<br/>    precedence  = optional(number, 50)<br/>    name        = optional(string)<br/>    description = optional(string)<br/>    enabled     = optional(bool)<br/>    actions = optional(map(object({<br/>      set_package_state   = optional(string)<br/>      add_package_tags    = optional(set(string))<br/>      remove_package_tags = optional(set(string))<br/>      precedence          = optional(number)<br/>    })), { quarantine = { set_package_state = "QUARANTINED" } })<br/>  })</pre> | `{}` | no |
| cooldown | The cooldown policy hides new upstream package versions from the repository index until they reach a minimum age.<br/>A null attribute keeps the value in the recipe. Set the variable to null to not create the policy.<br/>A workspace can have only one cooldown policy. | <pre>object({<br/>    within_past_days       = optional(number)<br/>    supported_formats      = optional(set(string))<br/>    included_repositories  = optional(set(string))<br/>    excluded_repositories  = optional(set(string))<br/>    include_local_packages = optional(bool)<br/>    precedence             = optional(number, 10)<br/>    name                   = optional(string)<br/>    description            = optional(string)<br/>    enabled                = optional(bool)<br/>    actions = optional(map(object({<br/>      set_package_state   = optional(string)<br/>      add_package_tags    = optional(set(string))<br/>      remove_package_tags = optional(set(string))<br/>      precedence          = optional(number)<br/>    })), { hide = { set_package_state = "HIDDEN" } })<br/>  })</pre> | `{}` | no |
| copyleft\_licenses | The copyleft license policy matches packages whose declared license, or any SBOM component license, is in `licenses`.<br/>A null attribute keeps the value in the recipe. Set the variable to null to not create the policy. | <pre>object({<br/>    licenses    = optional(set(string))<br/>    precedence  = optional(number, 20)<br/>    name        = optional(string)<br/>    description = optional(string)<br/>    enabled     = optional(bool)<br/>    actions = optional(map(object({<br/>      set_package_state   = optional(string)<br/>      add_package_tags    = optional(set(string))<br/>      remove_package_tags = optional(set(string))<br/>      precedence          = optional(number)<br/>    })), { tag = { add_package_tags = ["copyleft-license"] } })<br/>  })</pre> | `{}` | no |
| enabled | Set to true to evaluate the policies. Cloudsmith evaluates packages again when a policy is created or changed. | `bool` | `true` | no |
| high\_risk\_vulnerabilities | The high-risk vulnerability policy matches packages with a fixable vulnerability at or above `cvss_threshold`.<br/>The policy ignores the vulnerability IDs and aliases in `ignored_ids`.<br/>A null attribute keeps the value in the recipe. Set the variable to null to not create the policy. | <pre>object({<br/>    cvss_threshold = optional(number)<br/>    ignored_ids    = optional(set(string))<br/>    precedence     = optional(number, 30)<br/>    name           = optional(string)<br/>    description    = optional(string)<br/>    enabled        = optional(bool)<br/>    actions = optional(map(object({<br/>      set_package_state   = optional(string)<br/>      add_package_tags    = optional(set(string))<br/>      remove_package_tags = optional(set(string))<br/>      precedence          = optional(number)<br/>    })), { quarantine = { set_package_state = "QUARANTINED" } })<br/>  })</pre> | `{}` | no |
| malware | The malware policy matches packages with a MAL- vulnerability ID or the CWE-506 weakness. Set to null to not create the policy. | <pre>object({<br/>    precedence  = optional(number, 60)<br/>    name        = optional(string)<br/>    description = optional(string)<br/>    enabled     = optional(bool)<br/>    actions = optional(map(object({<br/>      set_package_state   = optional(string)<br/>      add_package_tags    = optional(set(string))<br/>      remove_package_tags = optional(set(string))<br/>      precedence          = optional(number)<br/>    })), { quarantine = { set_package_state = "QUARANTINED" } })<br/>  })</pre> | `{}` | no |
| name\_prefix | A prefix for the name of each policy. Policy names must be unique in a workspace. | `string` | `""` | no |
| recipes\_ref | The rego-recipes Git reference to download. Defaults to master; upstream changes can appear in subsequent plans. | `string` | `"master"` | no |
| recipes\_url | The base URL to download the rego-recipes repository files from. Change it to use a mirror. | `string` | `"https://raw.githubusercontent.com/cloudsmith-io/rego-recipes"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| policies | The created policies, keyed by recipe name. |
| rego | The rendered Rego source of each created policy, keyed by recipe name. |
<!-- END_TF_DOCS -->
