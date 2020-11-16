terraform {
  backend "s3" {
    bucket  = "eks-remote-terraform-state"
    key     = "terraform.tfstate"
    encrypt = true
    region  = "us-west-2"
  }

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  profile = "default"
  region = var.AWS_REGION
}
