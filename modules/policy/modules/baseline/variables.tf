variable "workspace" {
  description = "The slug of the Cloudsmith workspace that owns the policies."
  type        = string
  nullable    = false
}

variable "recipes_url" {
  description = "The base URL to download the rego-recipes repository files from. Change it to use a mirror."
  type        = string
  default     = "https://raw.githubusercontent.com/cloudsmith-io/rego-recipes"
  nullable    = false
}

variable "recipes_ref" {
  description = "The rego-recipes Git reference to download. Defaults to master; upstream changes can appear in subsequent plans."
  type        = string
  default     = "master"
  nullable    = false

  validation {
    condition     = length(trimspace(var.recipes_ref)) > 0
    error_message = "The recipes_ref value must not be empty."
  }
}

variable "name_prefix" {
  description = "A prefix for the name of each policy. Policy names must be unique in a workspace."
  type        = string
  default     = ""
  nullable    = false
}

variable "enabled" {
  description = "Set to true to evaluate the policies. Cloudsmith evaluates packages again when a policy is created or changed."
  type        = bool
  default     = true
  nullable    = false
}

variable "cooldown" {
  description = <<-EOT
    The cooldown policy hides new upstream package versions from the repository index until they reach a minimum age.
    A null attribute keeps the value in the recipe. Set the variable to null to not create the policy.
    A workspace can have only one cooldown policy.
  EOT
  type = object({
    within_past_days       = optional(number)
    supported_formats      = optional(set(string))
    included_repositories  = optional(set(string))
    excluded_repositories  = optional(set(string))
    include_local_packages = optional(bool)
    precedence             = optional(number, 10)
    name                   = optional(string)
    description            = optional(string)
    enabled                = optional(bool)
    actions = optional(map(object({
      set_package_state   = optional(string)
      add_package_tags    = optional(set(string))
      remove_package_tags = optional(set(string))
      precedence          = optional(number)
    })), { hide = { set_package_state = "HIDDEN" } })
  })
  default = {}

  validation {
    condition = try(var.cooldown.within_past_days == null, true) || try(
      var.cooldown.within_past_days >= 1 && floor(var.cooldown.within_past_days) == var.cooldown.within_past_days,
      false,
    )
    error_message = "The cooldown within_past_days value must be a whole number of 1 or more."
  }

  validation {
    condition = try(var.cooldown.supported_formats == null, true) || try(
      length(var.cooldown.supported_formats) > 0 &&
      length(setsubtract(var.cooldown.supported_formats, ["cargo", "conda", "docker", "go", "maven", "npm", "nuget", "python"])) == 0,
      false,
    )
    error_message = "The cooldown supported_formats value must contain one or more of cargo, conda, docker, go, maven, npm, nuget and python."
  }
}

variable "copyleft_licenses" {
  description = <<-EOT
    The copyleft license policy matches packages whose declared license, or any SBOM component license, is in `licenses`.
    A null attribute keeps the value in the recipe. Set the variable to null to not create the policy.
  EOT
  type = object({
    licenses    = optional(set(string))
    precedence  = optional(number, 20)
    name        = optional(string)
    description = optional(string)
    enabled     = optional(bool)
    actions = optional(map(object({
      set_package_state   = optional(string)
      add_package_tags    = optional(set(string))
      remove_package_tags = optional(set(string))
      precedence          = optional(number)
    })), { tag = { add_package_tags = ["copyleft-license"] } })
  })
  default = {}
}

variable "high_risk_vulnerabilities" {
  description = <<-EOT
    The high-risk vulnerability policy matches packages with a fixable vulnerability at or above `cvss_threshold`.
    The policy ignores the vulnerability IDs and aliases in `ignored_ids`.
    A null attribute keeps the value in the recipe. Set the variable to null to not create the policy.
  EOT
  type = object({
    cvss_threshold = optional(number)
    ignored_ids    = optional(set(string))
    precedence     = optional(number, 30)
    name           = optional(string)
    description    = optional(string)
    enabled        = optional(bool)
    actions = optional(map(object({
      set_package_state   = optional(string)
      add_package_tags    = optional(set(string))
      remove_package_tags = optional(set(string))
      precedence          = optional(number)
    })), { quarantine = { set_package_state = "QUARANTINED" } })
  })
  default = {}

  validation {
    condition = try(var.high_risk_vulnerabilities.cvss_threshold == null, true) || try(
      var.high_risk_vulnerabilities.cvss_threshold >= 0 && var.high_risk_vulnerabilities.cvss_threshold <= 10,
      false,
    )
    error_message = "The CVSS threshold must be between 0 and 10."
  }
}

variable "allowlist" {
  description = <<-EOT
    The allowlist policy matches packages in `entries`, in the format `format:name:version`.
    The default action makes the packages available again, after the policies with a lower precedence quarantine them.
    The module creates the policy only when `entries` is not empty. Set to null to omit it.
  EOT
  type = object({
    entries     = optional(set(string), [])
    precedence  = optional(number, 40)
    name        = optional(string)
    description = optional(string)
    enabled     = optional(bool)
    actions = optional(map(object({
      set_package_state   = optional(string)
      add_package_tags    = optional(set(string))
      remove_package_tags = optional(set(string))
      precedence          = optional(number)
    })), { allow = { set_package_state = "AVAILABLE" } })
  })
  default = {}

  validation {
    condition     = var.allowlist == null ? true : alltrue([for entry in var.allowlist.entries : can(regex("^[^:\\s]+:[^:\\s]+:[^:\\s]+$", entry))])
    error_message = "Each allowlist entry must have the format format:name:version."
  }
}

variable "blocklist" {
  description = <<-EOT
    The blocklist policy matches packages in `entries`, in the format `format:name` or `format:name:version`.
    The module creates the policy only when `entries` is not empty. Set to null to omit it.
  EOT
  type = object({
    entries     = optional(set(string), [])
    precedence  = optional(number, 50)
    name        = optional(string)
    description = optional(string)
    enabled     = optional(bool)
    actions = optional(map(object({
      set_package_state   = optional(string)
      add_package_tags    = optional(set(string))
      remove_package_tags = optional(set(string))
      precedence          = optional(number)
    })), { quarantine = { set_package_state = "QUARANTINED" } })
  })
  default = {}

  validation {
    condition     = var.blocklist == null ? true : alltrue([for entry in var.blocklist.entries : can(regex("^[^:\\s]+:[^:\\s]+(?::[^:\\s]+)?$", entry))])
    error_message = "Each blocklist entry must have the format format:name or format:name:version."
  }
}

variable "malware" {
  description = "The malware policy matches packages with a MAL- vulnerability ID or the CWE-506 weakness. Set to null to not create the policy."
  type = object({
    precedence  = optional(number, 60)
    name        = optional(string)
    description = optional(string)
    enabled     = optional(bool)
    actions = optional(map(object({
      set_package_state   = optional(string)
      add_package_tags    = optional(set(string))
      remove_package_tags = optional(set(string))
      precedence          = optional(number)
    })), { quarantine = { set_package_state = "QUARANTINED" } })
  })
  default = {}
}
