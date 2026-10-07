module "policy_baseline" {
  source = "../../modules/baseline"

  workspace = var.workspace

  cooldown = {
    within_past_days      = 7
    supported_formats     = ["npm", "python"]
    excluded_repositories = ["internal"]
    description           = "New upstream versions are available 7 days after they are published. Contact the platform team for an exemption."
  }

  high_risk_vulnerabilities = {
    cvss_threshold = 8.0
    ignored_ids    = ["CVE-2021-9999"]
  }

  allowlist = {
    entries = ["python:example-lib:1.2.3"]
  }

  blocklist = {
    entries = ["npm:compromised-ui", "python:malicious-lib:0.1.0"]
  }
}

output "policies" {
  value = module.policy_baseline.policies
}
