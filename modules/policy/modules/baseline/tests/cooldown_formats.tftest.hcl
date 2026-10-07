# Cloudsmith accepts a cooldown policy only for supported formats.
# These runs change one cooldown policy to each supported format, and then to all of them.

variables {
  name_prefix               = "tf-module-test: "
  enabled                   = false
  copyleft_licenses         = null
  high_risk_vulnerabilities = null
  malware                   = null
}

run "accepts_cargo" {
  variables {
    cooldown = { supported_formats = ["cargo"] }
  }

  assert {
    condition     = output.policies.cooldown.read_only
    error_message = "Cloudsmith did not accept a cooldown policy for cargo."
  }
}

run "accepts_conda" {
  variables {
    cooldown = { supported_formats = ["conda"] }
  }

  assert {
    condition     = output.policies.cooldown.read_only
    error_message = "Cloudsmith did not accept a cooldown policy for conda."
  }
}

run "accepts_docker" {
  variables {
    cooldown = { supported_formats = ["docker"] }
  }

  assert {
    condition     = output.policies.cooldown.read_only
    error_message = "Cloudsmith did not accept a cooldown policy for docker."
  }
}

run "accepts_go" {
  variables {
    cooldown = { supported_formats = ["go"] }
  }

  assert {
    condition     = output.policies.cooldown.read_only
    error_message = "Cloudsmith did not accept a cooldown policy for go."
  }
}

run "accepts_maven" {
  variables {
    cooldown = { supported_formats = ["maven"] }
  }

  assert {
    condition     = output.policies.cooldown.read_only
    error_message = "Cloudsmith did not accept a cooldown policy for maven."
  }
}

run "accepts_npm" {
  variables {
    cooldown = { supported_formats = ["npm"] }
  }

  assert {
    condition     = output.policies.cooldown.read_only
    error_message = "Cloudsmith did not accept a cooldown policy for npm."
  }
}

run "accepts_nuget" {
  variables {
    cooldown = { supported_formats = ["nuget"] }
  }

  assert {
    condition     = output.policies.cooldown.read_only
    error_message = "Cloudsmith did not accept a cooldown policy for nuget."
  }
}

run "accepts_python" {
  variables {
    cooldown = { supported_formats = ["python"] }
  }

  assert {
    condition     = output.policies.cooldown.read_only
    error_message = "Cloudsmith did not accept a cooldown policy for python."
  }
}

run "accepts_all_supported_formats" {
  variables {
    cooldown = { supported_formats = ["cargo", "conda", "docker", "go", "maven", "npm", "nuget", "python"] }
  }

  assert {
    condition     = output.policies.cooldown.read_only
    error_message = "Cloudsmith did not accept a cooldown policy for all the supported formats."
  }
}
