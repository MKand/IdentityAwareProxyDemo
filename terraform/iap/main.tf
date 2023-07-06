#https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/tree/master/blueprints/serverless/cloud-run-explore

data "google_project" "project" {
    project_id = var.project_id
}

locals {
    service_name_1 = "ping"
    service_name_2 = "pong"
}

module "cloud_run_1" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/cloud-run?depth=2"
  project_id = var.project_id
  name       = local.service_name_1
  region     = var.region
  containers = {
    hello-ping = {
    ports = {
       PORT1 = {
        container_port = 5000
        }
    }
      image = var.image
      env = {
        PROJECT_NUMBER = data.google_project.project.number
        BACKEND_SERVICE_ID = data.google_compute_backend_service.service_1.generated_id
        PROXY_HOST = "https://ping.manasakandula.tech"
        RANDOM_ID = timestamp() # used to force a recreate at every run
        SERVICE_HOST = local.service_name_1

      }
}
  }
  iam = {
    "roles/run.invoker" = ["serviceAccount:${google_project_service_identity.iap_sa.email}"]
  }
  ingress_settings = var.ingress_settings
  depends_on = [ module.glb_1 ]
}

module "cloud_run_2" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/cloud-run?depth=2"
  project_id = var.project_id
  name       = local.service_name_2
  region     = var.region
  containers = {
    hello-ping = {
    ports = {
       PORT1 = {
        container_port = 5000
        }
    }
      image = var.image
      env = {
        PROJECT_NUMBER = data.google_project.project.number
        BACKEND_SERVICE_ID = data.google_compute_backend_service.service_2.generated_id
        PROXY_HOST ="https://pong.manasakandula.tech"
        RANDOM_ID = timestamp() # used to force a recreate at every run
        SERVICE_HOST = local.service_name_2
      }
}
  }
  iam = {
    "roles/run.invoker" = ["serviceAccount:${google_project_service_identity.iap_sa.email}"]
  }
  ingress_settings = var.ingress_settings
  depends_on = [ module.glb_2 ]
}


# Reserved static IP for the Load Balancer
resource "google_compute_global_address" "service_1" {
  project = var.project_id
  name    = "glb-ip-1"
}

resource "google_compute_global_address" "service_2" {
  project = var.project_id
  name    = "glb-ip-2"
}

# Global L7 HTTPS Load Balancer in front of Cloud Run
module "glb_1" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-lb-app-ext?depth=2"
  project_id = var.project_id
  name       = "glb-1"
  address    = google_compute_global_address.service_1.address
  backend_service_configs = {
    default = {
      backends = [
        { backend = "neg-0" }
      ]
      health_checks = []
      port_name     = "http"

      iap_config = try({
        oauth2_client_id     = google_iap_client.iap_client_1.client_id,
        oauth2_client_secret = google_iap_client.iap_client_1.secret
      }, null)
    }
  }

  health_check_configs = {}
  neg_configs = {
    neg-0 = {
      cloudrun = {
        region = var.region
        target_service = {
         name  = local.service_name_1
        }
      }
    }
  }
  protocol = "HTTPS"
  ssl_certificates = {
    managed_configs = {
      default = {
        domains = [var.custom_domain_1]
      }
    }
  }
}

module "glb_2" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-lb-app-ext?depth=2"
  project_id = var.project_id
  name       = "glb-2"
  address    = google_compute_global_address.service_2.address
  backend_service_configs = {
    default = {
      backends = [
        { backend = "neg-0" }
      ]
      health_checks = []
      port_name     = "http"

      iap_config = try({
        oauth2_client_id     = google_iap_client.iap_client_2.client_id,
        oauth2_client_secret = google_iap_client.iap_client_2.secret
      }, null)
    }

  }

  health_check_configs = {}
  neg_configs = {
    neg-0 = {
      cloudrun = {
        region = var.region
        target_service = {
         name  = local.service_name_2
        }
      }
    }
  }
  protocol = "HTTPS"
  ssl_certificates = {
    managed_configs = {
      default = {
        domains = [var.custom_domain_2]
      }
    }
  }
}


# Identity-Aware Proxy (IAP) or OAuth brand (see OAuth consent screen)
# Note:
# Only "Organization Internal" brands can be created programmatically
# via API. To convert it into an external brand please use the GCP
# Console.
# Brands can only be created once for a Google Cloud project and the
# underlying Google API doesn't support DELETE or PATCH methods.
# Destroying a Terraform-managed Brand will remove it from state but
# will not delete it from Google Cloud.
# resource "google_iap_brand" "iap_brand" {
#   project = data.google_project.project.number
#   support_email     = "admin@manasakandula.altostrat.com"# var.iap.email
#   application_title = var.iap.app_title

# }

# IAP owned OAuth2 client
# Note:
# Only internal org clients can be created via declarative tools.
# External clients must be manually created via the GCP console.
# Warning:
# All arguments including secret will be stored in the raw state as plain-text.
resource "google_iap_client" "iap_client_1" {
  display_name = local.service_name_1
  brand        = "projects/${data.google_project.project.number}/brands/${data.google_project.project.number}"
}

resource "google_iap_client" "iap_client_2" {
  display_name = local.service_name_2
  brand        = "projects/${data.google_project.project.number}/brands/${data.google_project.project.number}"
}


# IAM policy for IAP
# For simplicity we use the same email as support_email and authorized member
resource "google_iap_web_iam_member" "iap_iam" {
  project = var.project_id
  role    = "roles/iap.httpsResourceAccessor"
  member  = "user:${var.iap.email}"
}

# SA service agent for IAP, which invokes CR
# Note:
# Once created, this resource cannot be updated or destroyed. These actions are a no-op.
resource "google_project_service_identity" "iap_sa" {
  provider = google-beta
  project  = var.project_id
  service  = "iap.googleapis.com"
}

data "google_compute_backend_service" "service_1" {
  name          = module.glb_1.backend_service_names.default
  project = var.project_id
}

data "google_compute_backend_service" "service_2" {
  name          = module.glb_2.backend_service_names.default
  project = var.project_id
}