locals {
  # Use locals for node groups to enforce required tags
  node_groups = {
    oncokb-compute = {
      instance_types = ["c6a.xlarge"]
      ami_type       = "BOTTLEROCKET_x86_64"
      desired_size   = 1
      max_size       = 1
      min_size       = 1
      taints = {
        dedicated = {
          key    = var.TAINT_KEY
          value  = "oncokb-compute"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "oncokb-compute"
      }
    }
    oncokb-eu = {
      instance_types = ["r5a.xlarge"]
      ami_type       = "BOTTLEROCKET_x86_64"
      desired_size   = 2
      max_size       = 2
      min_size       = 2
      taints = {
        dedicated = {
          key    = var.TAINT_KEY
          value  = "oncokb-eu"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "oncokb-eu"
      }
    }
    addons = {
      instance_types = ["m5.large"]
      ami_type       = "BOTTLEROCKET_x86_64"
      desired_size   = 1
      max_size       = 1
      min_size       = 1
    }
  }
}

module "eks_cluster" {
  source       = "git::https://github.com/MSK-Staging/terraform-aws-hyc-eks.git"
  cluster_name = var.CLUSTER_NAME

  # General EKS Config
  cluster_version = var.CLUSTER_VER
  tags = {
    Environment = var.CLUSTER_ENV
  }

  # Network Config
  vpc_id                   = var.VPC_ID
  control_plane_subnet_ids = var.CONTROL_PLANE_SUBNET_IDS
  subnet_ids               = var.SUBNET_IDS

  # API Controls
  cluster_endpoint_public_access  = var.API_PUBLIC
  cluster_endpoint_private_access = var.API_PRIVATE

  hyc_addon_configs = {
    efscsi = {
      create = false
    }
  }

  # EKS Managed Node Groups
  eks_managed_node_groups = {
    for name, config in local.node_groups : name => merge(config, {
      tags = merge(
        try(config.tags, {}),
        {
          "nodegroup-name" = name
        }
      )
    })
  }
}