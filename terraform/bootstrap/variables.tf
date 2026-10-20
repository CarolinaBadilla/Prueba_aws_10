variable "aws_region" {
  description = "Región de AWS donde desplegar los recursos"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Nombre globalmente único para el bucket S3 del estado"
  type        = string
  # Cambia esto con tu identificador único (solo minúsculas, números y guiones)
  default     = "enterprise-tfstate-badilla-2005"
}

variable "dynamodb_table_name" {
  description = "Nombre de la tabla DynamoDB para locking"
  type        = string
  default     = "enterprise-tfstate-locks"
}