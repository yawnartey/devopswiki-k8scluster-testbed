terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"

    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "random_id" "devops_wiki_randomid" {
  byte_length = 8
}

# backend bucket
resource "google_storage_bucket" "production" {
  name          = "devops-wiki-terraform-state-${random_id.devops_wiki_randomid.hex}"
  location      = var.region
  storage_class = "STANDARD"
  force_destroy = false

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  labels = {
    managed_by = "terraform"
  }

  public_access_prevention = "enforced"
}
