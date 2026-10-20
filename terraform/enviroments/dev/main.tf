data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "enterprise-dev-vpc"
  cidr = var.vpc_cidr

  # Tomamos las primeras 3 zonas de disponibilidad de la región (us-east-1a, 1b, 1c)
  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  # NAT Gateway: Para que los pods en subnets privadas tengan salida a descargar imágenes/paquetes.
  # Usamos un solo NAT Gateway para ahorrar costos en dev (en prod se usa uno por zona).
  enable_nat_gateway     = true
  single_nat_gateway     = true
  enable_dns_hostnames   = true
  enable_dns_support     = true

  # Tags requeridos por AWS Load Balancer Controller para descubrir automáticamente las subnets
  public_subnet_tags = {
    "kubernetes.io/role/elb"                      = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"             = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.30"

  # El API server es accesible públicamente para interactuar con kubectl desde tu terminal
  cluster_endpoint_public_access = true

  # Conecta el clúster a la VPC y coloca los nodos de trabajo en las subredes privadas
  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  # OIDC habilitado para autenticación segura pod-a-AWS (IRSA)
  enable_irsa = true

  # Permite que el usuario/rol que corre Terraform sea administrador del clúster automáticamente
  enable_cluster_creator_admin_permissions = true

  # Grupo de nodos administrados (Worker Nodes)
  eks_managed_node_groups = {
    general = {
      name           = "enterprise-node-group"
      instance_types = ["t3.micro"]

      ami_type = "AL2023_x86_64_STANDARD"

      min_size     = 1
      max_size     = 3
      desired_size = 2

      capacity_type = "ON_DEMAND"

      tags = {
        Environment = "dev"
        NodeGroup   = "general-workloads"
      }
    }
  }

  tags = {
    Environment = "dev"
    NodeGroup   = "general-workloads"
  }
}