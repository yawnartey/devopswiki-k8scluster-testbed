# allow internal communication between all subnets
resource "google_compute_firewall" "devopswiki-allow-internal" {
  name    = "allow-internal"
  project = var.project_id
  network = var.vpc_name
  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }
  source_ranges = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]
  description = "Allow internal traffic between devopswiki subnets only"
}

# allow http and https on frontend vms only
resource "google_compute_firewall" "devopswiki-allow-http-https" {
  name    = "allow-http-https"
  network = var.vpc_name
  project = var.project_id
  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["frontend"]
  priority      = 1000
}

# allow iap ssh
resource "google_compute_firewall" "devopswiki-allow-iap-ssh" {
  name    = "devopswiki-allow-iap-ssh"
  network = var.vpc_name
  project = var.project_id
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["iap-ssh"]
}
