output "instance_connection_name" {
  description = "Connection name of the instance"
  value       = google_sql_database_instance.mysql.connection_name
}

output "instance_ip" {
  description = "IP address of the instance"
  value       = google_sql_database_instance.mysql.ip_address[0].ip_address
}

output "database_name" {
  description = "Database name"
  value       = google_sql_database.database.name
}
