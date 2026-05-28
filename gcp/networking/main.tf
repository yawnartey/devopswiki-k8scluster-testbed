# vpc
resource "google_compute_network" "devopswiki-vpc" {
  name                    = "devopswiki-vpc"
  project                 = var.project_id
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"
  description             = "DevOps WiKi VPC"
}

# subnet
resource "google_compute_subnetwork" "devopswiki-subnet" {
  for_each = {
    "fe-subnet" = "10.0.1.0/24",
    "be-subnet" = "10.0.2.0/24"
  }
  name          = each.key
  ip_cidr_range = each.value
  region        = var.region
  network       = google_compute_network.devopswiki-vpc.id
  #private be-subnet VM to google APIs
  private_ip_google_access = each.key == "be-subnet" ? true : false
}

# route frontend to internet
resource "google_compute_route" "devopswiki-fe-route" {
  name             = "devopswiki-fe-internet-route"
  dest_range       = "0.0.0.0/0"
  network          = google_compute_network.devopswiki-vpc.name
  next_hop_gateway = "default-internet-gateway"
  tags             = ["frontend"]
  priority         = 1000
}

# cloud router
resource "google_compute_router" "devopswiki-router" {
  name    = "devopswiki-router"
  network = google_compute_network.devopswiki-vpc.name
  region  = var.region
  project = var.project_id
}

# allow fe-subnet to ssh into be-subnet internally
resource "google_compute_firewall" "devopswiki-allow-internal-ssh" {
  name    = "devopswiki-allow-internal-ssh"
  network = google_compute_network.devopswiki-vpc.name
  project = var.project_id
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_tags = ["frontend"]
  target_tags = ["backend"]
}

# cloud nat for outbound internet for private VMs in be-subnet
resource "google_compute_router_nat" "devopswiki-nat" {
  name                               = "devopswiki-nat"
  router                             = google_compute_router.devopswiki-router.name
  region                             = var.region
  project                            = var.project_id
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = google_compute_subnetwork.devopswiki-subnet["be-subnet"].id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}
