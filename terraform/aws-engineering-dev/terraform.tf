terraform {
  required_version = "~> 1.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.25.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.12.1"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "2.6.0"
    }

  }

  backend "s3" {
    bucket  = "terraform-zilliqa-hw"
    key     = "aws-engineering-dev"
    region  = "eu-central-1"
    profile = "z-shared-services-cicd"

    # dynamodb_table = "terraform-state-lock"
    encrypt = true
  }
}
