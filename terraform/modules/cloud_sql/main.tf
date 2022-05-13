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

    backup_configuration {
      enabled            = true
      binary_log_enabled = true
    }

    ip_configuration {
      ipv4_enabled    = true
      private_network = var.private_network_id
      
      authorized_networks {
        name  = "allow-all"
        value = "0.0.0.0/0"
      }
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
