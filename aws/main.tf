terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"

    }
  }

  backend "s3" {
    bucket       = "devopswiki-testbed-tf-state-bucket-8daccc39b5d2c2e9"
    key          = "state/terraform.tfstate"
    region       = "eu-west-3"
    encrypt      = true
    use_lockfile = true
    profile      = "lync"
  }
}

provider "aws" {
  region  = "eu-west-3"
  profile = "lync"
}

locals {
  yaw_priv_key_content = file(var.yaw_priv_key)
}

# networking module
module "networking" {
  source = "./networking"
}

# security group module
module "security_group" {
  source = "./security"
  vpc_id = module.networking.vpc_id
}

# iam module
module "iam" {
  source = "./iam"
}

# compute module
module "compute" {
  source                       = "./compute"
  subnet_ids                   = module.networking.subnet_ids
  testbed_cp_security_group_id = module.security_group.testbed_cp_security_group_id
  testbed_fe_security_group_id = module.security_group.testbed_fe_security_group_id
  testbed_be_security_group_id = module.security_group.testbed_be_security_group_id
  cluster_nodes_sg             = module.security_group.cluster_nodes_sg_id
  testbed_fe_instance_profile  = module.iam.testbed_fe_instance_profile_name
  yaw_public_key               = var.yaw_public_key
  yaw_priv_key                 = local.yaw_priv_key_content
  postgres_user                = var.postgres_user
  postgres_password            = var.postgres_password
}

# dns module
module "dns" {
  source         = "./dns"
  testbed_fe_eip = module.compute.testbed_fe_eip
}
