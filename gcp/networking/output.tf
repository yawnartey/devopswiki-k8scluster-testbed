output "vpc_id" {
  value = google_compute_network.devopswiki-vpc.id
}
output "subnet_ids" {
  value = { for k, s in google_compute_subnetwork.devopswiki-subnet : k => s.id }
}
output "vpc_name" {
  value = google_compute_network.devopswiki-vpc.name
}
