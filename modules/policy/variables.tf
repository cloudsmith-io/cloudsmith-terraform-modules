variable "workspace" {
  description = "The slug of the Cloudsmith workspace that owns the policy."
  type        = string
}

variable "name" {
  description = "The name of the policy."
  type        = string
}

variable "description" {
  description = "The description of the policy. Cloudsmith shows it to users when the policy blocks a package."
  type        = string
  default     = null
}

variable "rego" {
  description = "The Rego source of the policy. The source must declare `package cloudsmith` and a `match` rule."
  type        = string
}

variable "enabled" {
  description = "Set to true to evaluate the policy."
  type        = bool
  default     = true
}

variable "is_terminal" {
  description = "Set to true to stop the evaluation of other policies when this policy matches."
  type        = bool
  default     = false
}

variable "precedence" {
  description = "The evaluation order of the policy relative to other policies in the workspace. Cloudsmith assigns a value when it is null."
  type        = number
  default     = null
}

variable "actions" {
  description = <<-EOT
    The actions to apply to packages that match the policy, keyed by a stable name.
    Set exactly one of `set_package_state`, `add_package_tags` or `remove_package_tags` in each action.
  EOT
  type = map(object({
    set_package_state   = optional(string)
    add_package_tags    = optional(set(string))
    remove_package_tags = optional(set(string))
    precedence          = optional(number)
  }))
  default = {}

  validation {
    condition = alltrue([
      for action in values(var.actions) :
      length(compact([action.set_package_state, action.add_package_tags == null ? null : "add", action.remove_package_tags == null ? null : "remove"])) == 1
    ])
    error_message = "Set exactly one of set_package_state, add_package_tags or remove_package_tags in each action."
  }
}
