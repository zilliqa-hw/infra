module "aws_info" {
  source = "../aws-info"
  providers = {
    aws = aws.root-eu-central-1
  }
}

module "ecr_live" {
  # Live images are hosted in the Core Shared Services AWS account. 
  providers = {
    aws = aws.shared-services-eu-central-1
  }

  source      = "cloudposse/ecr/aws"
  version     = "0.32.2"
  namespace   = var.namespace
  image_names = ["${var.namespace}/${var.name}"]

  encryption_configuration = var.encryption_configuration
  image_tag_mutability     = "IMMUTABLE"
  principals_full_access   = ["arn:aws:iam::${module.aws_info.accounts.core.shared_services.id}:root"]
  principals_readonly_access = [
    "arn:aws:iam::${module.aws_info.accounts.engineering.dev.id}:root",
    "arn:aws:iam::${module.aws_info.accounts.engineering.prod.id}:root"
  ]
  scan_images_on_push = true
  tags                = var.tags
}

module "ecr_nonlive" {
  # Images generated from feature branch are hosted in the same account.
  providers = {
    aws = aws.default
  }
  source      = "cloudposse/ecr/aws"
  version     = "0.32.2"
  namespace   = var.namespace
  image_names = ["${var.namespace}/${var.name}"]


  encryption_configuration = var.encryption_configuration
  image_tag_mutability     = "MUTABLE"
  scan_images_on_push      = true
  tags                     = var.tags
}
