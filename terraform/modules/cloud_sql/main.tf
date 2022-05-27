resource "random_id" "db_suffix" {
  byte_length = 4
}

resource "google_sql_database_instance" "mysql" {
  name             = "inventory-db-${random_id.db_suffix.hex}"
  database_version = "MYSQL_8_0"
  region           = var.region

  settings {
    tier              = "db-f1-micro"
    availability_type = "ZONAL"
    disk_size         = 10
    disk_type         = "PD_SSD"

    # FEATURE: Configuración avanzada de backups
    backup_configuration {
      enabled                        = true
      binary_log_enabled            = true
      start_time                    = "03:00"
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7
      
      backup_retention_settings {
        retained_backups = 7
        retention_unit   = "COUNT"
      }
    }

    # FEATURE: Maintenance window
    maintenance_window {
      day          = 7
      hour         = 3
      update_track = "stable"
    }

    ip_configuration {
      ipv4_enabled    = true
      private_network = var.private_network_id
      
      authorized_networks {
        name  = "allow-all"
        value = "0.0.0.0/0"
      }
    }

    # FEATURE: Database flags
    database_flags {
      name  = "max_connections"
      value = "100"
    }

    database_flags {
      name  = "slow_query_log"
      value = "on"
    }
  }

  deletion_protection = false
}

resource "google_sql_database" "database" {
  name     = var.database_name
  instance = google_sql_database_instance.mysql.name
}

resource "google_sql_user" "user" {
  name     = var.database_user
  instance = google_sql_database_instance.mysql.name
  password = var.database_password
}
