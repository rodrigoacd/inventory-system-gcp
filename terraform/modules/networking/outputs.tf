output "network_id" {
  description = "Network ID"
  value       = google_compute_network.vpc.id
}

output "network_name" {
  description = "Network name"
  value       = google_compute_network.vpc.name
}

output "subnet_id" {
  description = "Subnet ID"
  value       = google_compute_subnetwork.subnet.id
}
