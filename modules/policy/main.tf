locals {
  has_hidden_action = anytrue([for action in values(var.actions) : try(action.set_package_state == "HIDDEN", false)])
}

resource "cloudsmith_policy" "this" {
  workspace   = var.workspace
  name        = var.name
  description = var.description
  rego        = var.rego
  enabled     = var.enabled
  is_terminal = var.is_terminal == null ? local.has_hidden_action : var.is_terminal
  precedence  = var.precedence

  lifecycle {
    postcondition {
      condition     = !(local.has_hidden_action && self.is_terminal) || self.read_only
      error_message = "Cloudsmith did not accept the policy as a cooldown policy, so the HIDDEN action has no effect. Use the cooldown recipe and change only its variables."
    }
  }
}

resource "cloudsmith_policy_action" "this" {
  for_each = var.actions

  workspace        = var.workspace
  policy_slug_perm = cloudsmith_policy.this.slug_perm
  precedence       = each.value.precedence

  dynamic "set_package_state" {
    for_each = each.value.set_package_state == null ? [] : [each.value.set_package_state]
    content {
      package_state = set_package_state.value
    }
  }

  dynamic "add_package_tags" {
    for_each = each.value.add_package_tags == null ? [] : [each.value.add_package_tags]
    content {
      tags = add_package_tags.value
    }
  }

  dynamic "remove_package_tags" {
    for_each = each.value.remove_package_tags == null ? [] : [each.value.remove_package_tags]
    content {
      tags = remove_package_tags.value
    }
  }
}
