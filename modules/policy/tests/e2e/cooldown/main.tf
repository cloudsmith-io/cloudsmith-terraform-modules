terraform {
  required_version = ">= 1.3"

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

variable "supported_formats" {
  description = "The package formats to evaluate."
  type        = set(string)
  default     = ["python"]
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

# Give each phase a separate URL path as well as its request_id cache buster.
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
    supported_formats     = var.supported_formats
    included_repositories = [cloudsmith_repository.this.slug]
  }
  copyleft_licenses         = null
  high_risk_vulnerabilities = null
  malware                   = null
}

output "cooldown" {
  value = module.baseline.policies.cooldown
}

output "download_roots" {
  value     = { for probe, entitlement in cloudsmith_entitlement.probe : probe => "https://dl.cloudsmith.io/${entitlement.token}/${var.workspace}/${cloudsmith_repository.this.slug}/python" }
  sensitive = true
}
