# Default AWS account
provider "aws" {
  region  = "eu-central-1"
  profile = "z-engineering-dev-cicd"

  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  region  = "us-west-2"
  alias   = "engineering-dev-us-west-2"
  profile = "z-engineering-dev-cicd"

  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  region  = "us-east-1"
  alias   = "engineering-dev-us-east-1"
  profile = "z-engineering-dev-cicd"

  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  region  = "us-west-2"
  alias   = "audit-us-west-2"
  profile = "z-audit-cicd"

  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  region  = "us-west-2"
  alias   = "shared-services-us-west-2"
  profile = "z-shared-services-cicd"

  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  region  = "eu-central-1"
  alias   = "shared-services-eu-central-1"
  profile = "z-shared-services-cicd"

  default_tags {
    tags = local.default_tags
  }
}


provider "aws" {
  region  = "us-west-2"
  alias   = "root-us-west-2"
  profile = "z-root-cicd"

  default_tags {
    tags = local.default_tags
  }
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}
