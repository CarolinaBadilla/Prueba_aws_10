terraform {
  backend "s3" {
    bucket         = "enterprise-tfstate-badilla-2005" # <-- El nombre exacto de tu bucket
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    use_lockfile = true
  }
}