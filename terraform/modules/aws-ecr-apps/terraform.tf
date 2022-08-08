terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.default, aws.shared-services-eu-central-1, aws.root-eu-central-1]
    }
  }
}
