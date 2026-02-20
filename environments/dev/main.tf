terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "storage" {
  source           = "../../modules/storage"
  bucket_base_name = "jabu-datalake"
  environment      = "dev"
}

module "processing" {
  source     = "../../modules/processing"
  bucket_arn = module.storage.bucket_arn
  bucket_id  = module.storage.bucket_name
}