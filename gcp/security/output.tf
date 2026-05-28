output "internal-sg" {
  value = google_compute_firewall.devopswiki-allow-internal.id
}
output "http-https" {
  value = google_compute_firewall.devopswiki-allow-http-https.id
}
output "iap-ssh" {
  value = google_compute_firewall.devopswiki-allow-iap-ssh.id
}
