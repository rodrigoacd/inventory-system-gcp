output "service_url" {
  description = "URL of the Cloud Run service"
  value       = google_cloud_run_service.app.status[0].url
}

output "service_name" {
  description = "Name of the Cloud Run service"
  value       = google_cloud_run_service.app.name
}
