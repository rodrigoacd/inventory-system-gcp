output "cloud_run_url" {
  description = "URL of the Cloud Run service"
  value       = module.cloud_run.service_url
}

output "cloud_sql_connection_name" {
  description = "Cloud SQL connection name"
  value       = module.cloud_sql.instance_connection_name
}

output "cloud_sql_instance_ip" {
  description = "Cloud SQL instance IP address"
  value       = module.cloud_sql.instance_ip
}

output "bucket_name" {
  description = "Cloud Storage bucket name"
  value       = module.cloud_storage.bucket_name
}

output "bucket_url" {
  description = "Cloud Storage bucket URL"
  value       = module.cloud_storage.bucket_url
}
