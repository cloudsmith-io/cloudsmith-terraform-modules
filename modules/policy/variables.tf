variable "workspace" {
  description = "The slug of the Cloudsmith workspace that owns the policy."
  type        = string
  nullable    = false
}

variable "name" {
  description = "The name of the policy."
  type        = string
  nullable    = false
}

variable "description" {
  description = "The description of the policy. Cloudsmith shows it to users when the policy blocks a package."
  type        = string
  default     = null
}

variable "rego" {
  description = "The Rego source of the policy. The source must declare `package cloudsmith` and a `match` rule."
  type        = string
  nullable    = false
}

variable "enabled" {
  description = "Set to true to evaluate the policy."
  type        = bool
  default     = true
  nullable    = false
}

variable "is_terminal" {
  description = "Set to true to stop the evaluation of other policies when this policy matches."
  type        = bool
  default     = false
  nullable    = false
}

variable "precedence" {
  description = "The evaluation order of the policy relative to other policies in the workspace. Cloudsmith assigns a value when it is null."
  type        = number
  default     = null

  validation {
    condition     = var.precedence == null ? true : floor(var.precedence) == var.precedence
    error_message = "The policy precedence must be a whole number."
  }
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
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for action in values(var.actions) :
      action == null ? false : length([
        for configured in [action.set_package_state != null, action.add_package_tags != null, action.remove_package_tags != null] :
        configured if configured
      ]) == 1
    ])
    error_message = "Set exactly one of set_package_state, add_package_tags or remove_package_tags in each action."
  }

  validation {
    condition = alltrue([
      for action in values(var.actions) :
      try(action.set_package_state == null ? true : contains(["AVAILABLE", "DELETED", "QUARANTINED", "HIDDEN"], action.set_package_state), false)
    ])
    error_message = "The package state must be AVAILABLE, DELETED, QUARANTINED or HIDDEN."
  }

  validation {
    condition = alltrue([
      for action in values(var.actions) :
      try(action.precedence == null ? true : floor(action.precedence) == action.precedence, false)
    ])
    error_message = "Each action precedence must be a whole number."
  }
}
