output "default_URL" {
  description = "Cloud Run service default URL."
  value       = module.cloud_run.service.status[0].url
}

output "load_balancer_ip" {
  description = "LB IP that forwards to Cloud Run service."
  value       = module.glb.address
}

output "backend_service_id" {
  description = "LB IP that forwards to Cloud Run service."
  value       = data.google_compute_backend_service.default.generated_id
}