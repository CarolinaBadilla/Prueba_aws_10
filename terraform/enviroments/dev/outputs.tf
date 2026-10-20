output "vpc_id" {
  description = "ID de la VPC creada"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "IDs de las subredes privadas para los nodos de cómputo"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "IDs de las subredes públicas para los balanceadores"
  value       = module.vpc.public_subnets
}

output "cluster_name" {
  description = "Nombre del clúster EKS"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint del API server de Kubernetes"
  value       = module.eks.cluster_endpoint
}

output "configure_kubectl" {
  description = "Comando para configurar la conexión de kubectl con el clúster"
  value       = "aws eks --region ${var.aws_region} update-kubeconfig --name ${module.eks.cluster_name}"
}