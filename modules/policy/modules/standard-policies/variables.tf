variable "workspace" {
  description = "The slug of the Cloudsmith workspace that owns the policies."
  type        = string
  nullable    = false
}

variable "vulnerability_policies" {
  description = "The vulnerability policies, keyed by policy name. Cloudsmith flags packages with a vulnerability at or above `min_severity`."
  type = map(object({
    description             = optional(string)
    min_severity            = optional(string, "Critical")
    on_violation_quarantine = optional(bool, false)
    allow_unknown_severity  = optional(bool, false)
    package_query_string    = optional(string)
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for policy in values(var.vulnerability_policies) :
      try(contains(["Low", "Medium", "High", "Critical"], policy.min_severity), false)
    ])
    error_message = "The minimum severity must be Low, Medium, High or Critical."
  }
}

variable "license_policies" {
  description = "The license policies, keyed by policy name. Cloudsmith flags packages with a license in `spdx_identifiers`."
  type = map(object({
    description             = string
    spdx_identifiers        = set(string)
    on_violation_quarantine = optional(bool, false)
    allow_unknown_licenses  = optional(bool, false)
    package_query_string    = optional(string)
  }))
  default  = {}
  nullable = false
}

variable "deny_policies" {
  description = "The package deny policies, keyed by policy name. Cloudsmith blocks the download of packages that match `package_query`."
  type = map(object({
    description   = optional(string)
    package_query = string
    enabled       = optional(bool, true)
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for policy in values(var.deny_policies) :
      try(length(trimspace(policy.package_query)) > 0 && length(policy.package_query) <= 256, false)
    ])
    error_message = "Each package deny query must contain between 1 and 256 characters and cannot be blank."
  }
}
