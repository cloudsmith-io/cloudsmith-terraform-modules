terraform {
  required_version = ">= 1.15"

  required_providers {
    cloudsmith = {
      source  = "cloudsmith-io/cloudsmith"
      version = ">= 0.0.81"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9"
    }
  }
}

variable "workspace" {
  type = string
}

variable "slug_perm" {
  type = string
}

# The API reads from a database replica. The wait lets the last policy change reach the replica before the read.
resource "time_sleep" "replica" {
  create_duration = "30s"
}

data "cloudsmith_policy" "this" {
  workspace        = var.workspace
  policy_slug_perm = var.slug_perm

  depends_on = [time_sleep.replica]
}

output "policy" {
  value = data.cloudsmith_policy.this
}
