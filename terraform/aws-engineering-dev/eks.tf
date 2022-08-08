data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "18.26.6"
  cluster_name    = local.cluster_name
  cluster_version = "1.22"
  subnet_ids      = module.vpc["dev"].private_subnet_ids
  vpc_id          = module.vpc["dev"].vpc_id
  enable_irsa     = true

  prefix_separator                   = ""
  iam_role_name                      = "ZilliqaEKS-${local.cluster_name}"
  iam_role_use_name_prefix           = false
  cluster_security_group_name        = local.cluster_name
  cluster_security_group_description = "EKS cluster security group."

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cluster_encryption_config = [
    {
      provider_key_arn = aws_kms_key.keys["eks"].arn
      resources        = ["secrets"]
    }
  ]

  # Extend cluster security group rules
  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }

  # Extend node-to-node security group rules
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    # This is needed for the Ingress Admission Controller, probably 8443 would be enough.
    ingress_cluster_all = {
      description                   = "Cluster to node all ports/protocols"
      protocol                      = "-1"
      from_port                     = 0
      to_port                       = 0
      type                          = "ingress"
      source_cluster_security_group = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  eks_managed_node_group_defaults = {
    ami_type  = "AL2_x86_64"
    disk_size = 20

    # We are using the IRSA created below for permissions
    # However, we have to deploy with the policy attached FIRST (when creating a fresh cluster)
    # and then turn this off after the cluster/node group is created. Without this initial policy,
    # the VPC CNI fails to assign IPs and nodes cannot join the cluster
    # See https://github.com/aws/containers-roadmap/issues/1666 for more context
    iam_role_attach_cni_policy = true
  }

  eks_managed_node_groups = {
    t3a_large_spot = {
      name           = "t3a_large_spot"
      capacity_type  = "SPOT"
      instance_types = ["t3a.medium"]
      desired_size   = 3
      max_size       = 5
      min_size       = 2

      # launch_template_id      = aws_launch_template.default.id
      # launch_template_version = aws_launch_template.default.default_version

      # Enabling containerd and 
      # See issue https://github.com/awslabs/amazon-eks-ami/issues/844
      pre_bootstrap_user_data = <<-EOT
        #!/bin/bash
        set -ex
        cat <<-EOF > /etc/profile.d/bootstrap.sh
        export CONTAINER_RUNTIME="containerd"
        export USE_MAX_PODS=false
        export KUBELET_EXTRA_ARGS="--max-pods=110"
        EOF
        # Source extra environment variables in bootstrap script
        sed -i '/^set -o errexit/a\\nsource /etc/profile.d/bootstrap.sh' /etc/eks/bootstrap.sh
      EOT
    }
  }

  manage_aws_auth_configmap = true

  aws_auth_roles = [
    {
      rolearn  = aws_iam_role.cicd.arn
      username = "cicd"
      groups   = ["system:masters"]
    },
    {
      rolearn  = local.engineerviewer_arn
      username = "engineerviewer:{{SessionName}}"
      groups   = ["system:masters"]
    },
  ]
  # map_users    = var.map_users
  # map_accounts = var.map_accounts
}

output "eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane."
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane."
  value       = module.eks.cluster_security_group_id
}

output "eks_cluster_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
}

# output "eks_config_map_aws_auth" {
#   description = "A kubernetes configuration to authenticate to this EKS cluster."
#   value       = module.eks.config_map_aws_auth
# }

# @TODO: This won't work before the Ingress controller deployed.

#data "aws_lb" "k8s_ingress" {
#  tags = {
#   "kubernetes.io/service-name"                  = "ingress-nginx/ingress-ingress-nginx-controller"
#    "kubernetes.io/cluster/${local.cluster_name}" = "owned"
#  }
#}
