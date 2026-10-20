variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "Rango CIDR principal para la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "cluster_name" {
  description = "Nombre del clúster de EKS para los tags de red"
  type        = string
  default     = "enterprise-dev-eks"
}

variable "github_org" {
  description = "Usuario u organización de GitHub"
  type        = string
  # Reemplaza con tu usuario exacto de GitHub
  default     = "CarolinaBadilla"
}

variable "github_repo" {
  description = "Nombre del repositorio en GitHub"
  type        = string
  default     = "Prueba_aws_10"
}