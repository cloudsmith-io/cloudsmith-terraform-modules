terraform {
  required_version = ">= 1.6"

  required_providers {
    cloudsmith = {
      source  = "cloudsmith-io/cloudsmith"
      version = ">= 0.0.81"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9"
    }
  }
}

variable "workspace" {
  description = "The slug of the Cloudsmith workspace."
  type        = string
}

variable "enabled" {
  description = "Set to true to enable the cooldown policy."
  type        = bool
}

variable "within_past_days" {
  description = "The cooldown window in days."
  type        = number
}

resource "random_id" "repository_suffix" {
  byte_length = 4
}

# The CDN caches the index of a public repository, so the test uses a private repository and an entitlement token.
resource "cloudsmith_repository" "this" {
  namespace = var.workspace
  name      = "tf-cooldown-e2e-${random_id.repository_suffix.hex}"
  slug      = "tf-cooldown-e2e-${random_id.repository_suffix.hex}"
}

# The CDN does not use the query string in its cache key. Each probe uses its own token, so that each probe has its own URL path.
resource "cloudsmith_entitlement" "probe" {
  for_each = toset(["disabled", "enabled", "shorter"])

  namespace  = var.workspace
  repository = cloudsmith_repository.this.slug_perm
  name       = "cooldown-e2e-probe-${each.key}"
}

resource "cloudsmith_repository_upstream" "pypi" {
  namespace     = var.workspace
  repository    = cloudsmith_repository.this.slug_perm
  name          = "PyPI"
  upstream_type = "python"
  upstream_url  = "https://pypi.org"
  mode          = "Cache and Proxy"
}

module "baseline" {
  source = "../../../modules/baseline"

  workspace   = var.workspace
  name_prefix = "${cloudsmith_repository.this.slug}: "
  enabled     = var.enabled

  cooldown = {
    within_past_days      = var.within_past_days
    supported_formats     = ["python"]
    included_repositories = [cloudsmith_repository.this.slug]
  }
  copyleft_licenses         = null
  high_risk_vulnerabilities = null
  malware                   = null
}

# The download service reads from a database replica. The wait lets each policy change reach the replica before the next probe.
resource "time_sleep" "policy_change" {
  create_duration = "30s"

  triggers = {
    enabled          = var.enabled
    within_past_days = var.within_past_days
  }

  depends_on = [module.baseline]
}

output "cooldown" {
  value = module.baseline.policies.cooldown
}

output "download_roots" {
  value     = { for probe, entitlement in cloudsmith_entitlement.probe : probe => "https://dl.cloudsmith.io/${entitlement.token}/${var.workspace}/${cloudsmith_repository.this.slug}/python" }
  sensitive = true
}

output "request_id" {
  value = random_id.repository_suffix.hex
}
