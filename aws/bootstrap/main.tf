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

}

provider "aws" {
  region  = "eu-west-3"
  profile = "lync"
}

# generate a random id to append to the bucket name
resource "random_id" "devopswiki_testbed_randomid" {
  byte_length = 8
}

# s3 bucket for remote state management 
resource "aws_s3_bucket" "devopswiki_testbed_tf_state" {
  bucket = "devopswiki-testbed-tf-state-bucket-${random_id.devopswiki_testbed_randomid.hex}"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name      = "DevOps WiKi Terraform State"
    ManagedBy = "terraform"
  }
}

# enable bucket versioning
resource "aws_s3_bucket_versioning" "devopswiki_testbed_tf_state_versioning" {
  bucket = aws_s3_bucket.devopswiki_testbed_tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# encrypt the state files
resource "aws_s3_bucket_server_side_encryption_configuration" "devopswiki_testbed_tf_state_encryption" {
  bucket = aws_s3_bucket.devopswiki_testbed_tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

# block public access to the bucket
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.devopswiki_testbed_tf_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# s3 bucket for let's encrypt
resource "aws_s3_bucket" "devopswiki_testbed_letsencrypt" {
  bucket = "devopswiki-testbed-letsencrypt-${random_id.devopswiki_testbed_randomid.hex}"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name      = "DevOps WiKi LetsEncrypt Certs"
    ManagedBy = "terraform"
  }
}

# enable bucket versioning
resource "aws_s3_bucket_versioning" "devopswiki_testbed_letsencrypt_versioning" {
  bucket = aws_s3_bucket.devopswiki_testbed_letsencrypt.id

  versioning_configuration {
    status = "Enabled"
  }
}

# encrypt the state files
resource "aws_s3_bucket_server_side_encryption_configuration" "devopswiki_testbed_letsencrypt_encryption" {
  bucket = aws_s3_bucket.devopswiki_testbed_letsencrypt.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

# block public access to the bucket
resource "aws_s3_bucket_public_access_block" "devopswiki_testbed_letsencrypt_public_access" {
  bucket = aws_s3_bucket.devopswiki_testbed_letsencrypt.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
