terraform {
  required_version = ">= 1.6"

  required_providers {
    cloudsmith = {
      source  = "cloudsmith-io/cloudsmith"
      version = ">= 0.0.81"
    }
  }
}

variable "workspace" {
  type = string
}

variable "slug_perm" {
  type = string
}

data "cloudsmith_policy" "this" {
  workspace        = var.workspace
  policy_slug_perm = var.slug_perm
}

output "policy" {
  value = data.cloudsmith_policy.this
}
