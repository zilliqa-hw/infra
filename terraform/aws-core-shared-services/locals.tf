locals {
  default_tags = {
    account       = "Core - Shared Services"
    is-production = true
    owner         = "aws+core-shared-services@mongodb.hu"
    terraform     = "infra/terraform/aws-core-shared-services"
  }
}
