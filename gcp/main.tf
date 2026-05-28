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
  backend "gcs" {
    bucket  = "devops-wiki-terraform-state-52b56ffcee4a9fe8"
    prefix  = "devopswiki-terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  credentials = file("~/.ssh/gcloud-auth-key.json")
}

resource "random_id" "devops_wiki_randomid" {
  byte_length = 8
}

# networking module
module "networking" {
  source = "./networking"
}

# security group module
module "security_group" {
  source = "./security"
  vpc_id = module.networking.vpc_id
  vpc_name = module.networking.vpc_name
}

# compute module
module "compute" {
  source = "./compute"
  vpc_id = module.networking.vpc_id
  subnet_ids = module.networking.subnet_ids

}