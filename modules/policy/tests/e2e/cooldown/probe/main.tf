terraform {
  required_version = ">= 1.6"

  required_providers {
    http = {
      source  = "hashicorp/http"
      version = ">= 3.4"
    }
  }
}

variable "download_root" {
  description = "The Python download root of the repository. It contains an entitlement token."
  type        = string
  sensitive   = true
}

variable "request_id" {
  description = "A value that is unique to each probe. The probe adds it to the URLs, so that the CDN does not return a cached response."
  type        = string
}

variable "download_versions" {
  description = "The six versions to request the wheel of."
  type        = set(string)
  default     = []
}

data "http" "index" {
  url                = "${var.download_root}/simple/six/?request_id=${var.request_id}"
  request_timeout_ms = 30000

  # The first request to a new repository fetches the index from the upstream, which can take longer than the timeout.
  retry {
    attempts     = 3
    min_delay_ms = 5000
  }
}

data "http" "wheel" {
  for_each = var.download_versions

  url                = "${var.download_root}/six-${each.key}-py2.py3-none-any.whl?request_id=${var.request_id}"
  method             = "HEAD"
  request_timeout_ms = 30000

  # The first request for a file fetches the file from the upstream, which can take longer than the timeout.
  retry {
    attempts     = 3
    min_delay_ms = 5000
  }
}

output "listed_versions" {
  description = "The six versions in the simple index."
  value       = toset([for match in regexall("six-([0-9]+\\.[0-9]+\\.[0-9]+)-py2\\.py3-none-any\\.whl", data.http.index.response_body) : match[0]])
}

output "download_status" {
  description = "The HTTP status of the wheel request, keyed by version."
  value       = { for version, wheel in data.http.wheel : version => wheel.status_code }
}
