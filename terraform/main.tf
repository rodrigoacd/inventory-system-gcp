terraform {
  required_version = ">= 1.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "run.googleapis.com",
    "sqladmin.googleapis.com",
    "storage.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "servicenetworking.googleapis.com",
    "vpcaccess.googleapis.com",
  ])

  service            = each.key
  disable_on_destroy = false
}

# VPC Network
module "networking" {
  source = "./modules/networking"
  
  project_id = var.project_id
  region     = var.region
}

# Cloud Storage
module "cloud_storage" {
  source = "./modules/cloud_storage"
  
  project_id    = var.project_id
  bucket_name   = var.bucket_name
  location      = var.region
}

# Cloud SQL
module "cloud_sql" {
  source = "./modules/cloud_sql"
  
  project_id          = var.project_id
  region              = var.region
  database_name       = var.database_name
  database_user       = var.database_user
  database_password   = var.database_password
  private_network_id  = module.networking.network_id
  
  depends_on = [
    google_project_service.required_apis,
    module.networking
  ]
}

# Cloud Run
module "cloud_run" {
  source = "./modules/cloud_run"
  
  project_id     = var.project_id
  region         = var.region
  service_name   = var.service_name
  image          = var.cloud_run_image
  
  env_vars = {
    DB_HOST         = module.cloud_sql.instance_connection_name
    DB_USER         = var.database_user
    DB_PASSWORD     = var.database_password
    DB_NAME         = var.database_name
    GCS_BUCKET_NAME = var.bucket_name
  }
  
  depends_on = [
    google_project_service.required_apis,
    module.cloud_sql,
    module.cloud_storage
  ]
}
