# compute image
data "google_compute_image" "rocky" {
  family  = "rocky-linux-9"
  project = "rocky-linux-cloud"
}

# static ip address for frontend only
resource "google_compute_address" "eip" {
  provider     = google
  name         = "fe-static-ip"
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"
}

# fe compute instance
resource "google_compute_instance" "devopswiki-fe" {
  name         = "devopswiki-fe"
  machine_type = "e2-medium"
  zone         = "${var.region}-a"
  tags         = ["frontend", "iap-ssh"]
  boot_disk {
    initialize_params {
      image = data.google_compute_image.rocky.self_link
      size  = 20
      type  = "pd-ssd"
    }
  }
  network_interface {
    network    = var.vpc_id
    subnetwork = var.subnet_ids["fe-subnet"]
    access_config {
      nat_ip = google_compute_address.eip.address
    }
  }
  labels = {
    environment = "production"
    role         = "frontend"
  }
}

# be compute instance
resource "google_compute_instance" "devopswiki-be" {
  name         = "devopswiki-be"
  machine_type = "e2-medium"
  zone         = "${var.region}-a"
  tags         = ["backend"]
  boot_disk {
    initialize_params {
      image = data.google_compute_image.rocky.self_link
      size  = 30
      type  = "pd-ssd"
    }
  }
  network_interface {
    network    = var.vpc_id
    subnetwork = var.subnet_ids["be-subnet"]
  }
  labels = {
    environment = "production"
    role         = "backend"
  }
}