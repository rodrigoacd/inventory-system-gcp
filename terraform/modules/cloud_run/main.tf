resource "google_cloud_run_service" "app" {
  name     = var.service_name
  location = var.region

  template {
    spec {
      containers {
        image = var.image
        
        dynamic "env" {
          for_each = var.env_vars
          content {
            name  = env.key
            value = env.value
          }
        }
        
        # FEATURE: Resource limits optimizados
        resources {
          limits = {
            cpu    = "2000m"
            memory = "1Gi"
          }
          requests = {
            cpu    = "1000m"
            memory = "512Mi"
          }
        }
        
        ports {
          container_port = 8080
        }

        # FEATURE: Startup probe
        startup_probe {
          http_get {
            path = "/health"
          }
          initial_delay_seconds = 10
          timeout_seconds       = 3
          period_seconds        = 10
          failure_threshold     = 3
        }

        # FEATURE: Liveness probe
        liveness_probe {
          http_get {
            path = "/health"
          }
          initial_delay_seconds = 30
          timeout_seconds       = 3
          period_seconds        = 30
        }
      }
      
      container_concurrency = 100
      timeout_seconds       = 300
    }
    
    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale"      = "100"
        "autoscaling.knative.dev/minScale"      = "1"
        "autoscaling.knative.dev/target"        = "80"
        "run.googleapis.com/cpu-throttling"     = "false"
        "run.googleapis.com/startup-cpu-boost"  = "true"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  autogenerate_revision_name = true
}

resource "google_cloud_run_service_iam_member" "public_access" {
  service  = google_cloud_run_service.app.name
  location = google_cloud_run_service.app.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}
