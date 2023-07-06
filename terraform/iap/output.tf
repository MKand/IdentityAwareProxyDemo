# output "default_URL" {
#   description = "Cloud Run service default URL."
#   value       = module.cloud_run.service.status[0].url
# }

output "load_balancer_ip_1" {
  description = "LB IP that forwards to Cloud Run service."
  value       = module.glb_1.address
}

output "load_balancer_ip_2" {
  description = "LB IP that forwards to Cloud Run service."
  value       = module.glb_2.address
}


output "backend_service_id_1" {
  description = "LB IP that forwards to Cloud Run service."
  value       = data.google_compute_backend_service.service_1.generated_id
}

output "backend_service_id_2" {
  description = "LB IP that forwards to Cloud Run service."
  value       = data.google_compute_backend_service.service_2.generated_id
}