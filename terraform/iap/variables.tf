variable "custom_domain" {
  description = "Custom domain for the Load Balancer."
  type        = string
  default     = null
}

variable "iap" {
  description = "Identity-Aware Proxy for Cloud Run in the LB."
  type = object({
    app_title          = optional(string, "Cloud Run Explore Application")
    oauth2_client_name = optional(string, "Test Client")
    email              = optional(string)
  })
  default = {}
}

variable "image" {
  description = "Container image to deploy."
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "ingress_settings" {
  description = "Ingress traffic sources allowed to call the service."
  type        = string
  default     = "all"
}


variable "project_id" {
  description = "Project ID."
  type        = string
}

variable "region" {
  description = "Cloud region where resource will be deployed."
  type        = string
  default     = "us-central1"
  }

