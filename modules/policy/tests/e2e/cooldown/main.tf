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

resource "cloudsmith_entitlement" "probe" {
  namespace  = var.workspace
  repository = cloudsmith_repository.this.slug_perm
  name       = "cooldown-e2e-probe"
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

output "cooldown" {
  value = module.baseline.policies.cooldown
}

output "download_root" {
  value     = "https://dl.cloudsmith.io/${cloudsmith_entitlement.probe.token}/${var.workspace}/${cloudsmith_repository.this.slug}/python"
  sensitive = true
}

output "request_id" {
  value = random_id.repository_suffix.hex
}
