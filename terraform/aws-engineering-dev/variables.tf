data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

module "aws_info" {
  source = "../modules/aws-info"
  providers = {
    aws = aws.root-us-west-2
  }
}

locals {
  caller_identity = data.aws_caller_identity.current
  region          = data.aws_region.current
  partition       = data.aws_partition.current
  environment     = "dev"

  default_tags = {
    account       = "Engineering - Dev"
    is-production = false
    owner         = "aws+engineering-dev@mongodb.hu"
    terraform     = "infra/terraform/aws-engineering-dev"
  }
  cluster_name       = "engineering-dev-eu-central-1"
  engineerviewer_arn = "arn:aws:iam::338149388389:role/AWSReservedSSO_EngineerViewer_b2d21cd3a0fdf68f"
  eks_oidc_issuer    = substr(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, 8, -1)

  k8s_ingress = {
    api = "knotes"
  }
}
