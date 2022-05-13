variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "service_name" {
  description = "Cloud Run service name"
  type        = string
  default     = "inventory-system"
}

variable "cloud_run_image" {
  description = "Container image for Cloud Run"
  type        = string
}

variable "bucket_name" {
  description = "Cloud Storage bucket name"
  type        = string
}

variable "database_name" {
  description = "Database name"
  type        = string
  default     = "inventory"
}

variable "database_user" {
  description = "Database user"
  type        = string
  default     = "inventory_user"
}

variable "database_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}
