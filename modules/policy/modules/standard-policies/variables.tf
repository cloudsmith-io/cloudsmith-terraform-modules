variable "workspace" {
  description = "The slug of the Cloudsmith workspace that owns the policies."
  type        = string
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
  default = {}
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
  default = {}
}

variable "deny_policies" {
  description = "The package deny policies, keyed by policy name. Cloudsmith blocks the download of packages that match `package_query`."
  type = map(object({
    description   = optional(string)
    package_query = string
    enabled       = optional(bool, true)
  }))
  default = {}
}
