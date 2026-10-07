terraform {
  required_version = ">= 1.15"

  required_providers {
    cloudsmith = {
      source  = "cloudsmith-io/cloudsmith"
      version = ">= 0.0.81"
    }
    http = {
      source  = "hashicorp/http"
      version = ">= 3.4"
    }
  }
}
