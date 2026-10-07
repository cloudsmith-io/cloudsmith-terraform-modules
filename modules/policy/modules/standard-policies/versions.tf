terraform {
  required_version = ">= 1.3"

  required_providers {
    cloudsmith = {
      source  = "cloudsmith-io/cloudsmith"
      version = ">= 0.0.81"
    }
  }
}
