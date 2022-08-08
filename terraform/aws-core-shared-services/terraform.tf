terraform {
  required_version = "~> 1.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.25.0"
    }
  }

  backend "s3" {
    bucket  = "terraform-zilliqa-hw"
    key     = "aws-core-shared-services"
    region  = "eu-central-1"
    profile = "z-shared-services-cicd"

    # dynamodb_table = "terraform-state-lock"
    encrypt = true
  }
}
