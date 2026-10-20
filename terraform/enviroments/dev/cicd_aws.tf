# -------------------------------------------------------------
# 1. Repositorios de Amazon ECR para Backend y Frontend
# -------------------------------------------------------------

resource "aws_ecr_repository" "backend" {
  name                 = "enterprise-backend"
  image_tag_mutability = "MUTABLE"

  # Escaneo automático de vulnerabilidades CVE al hacer push
  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

resource "aws_ecr_repository" "frontend" {
  name                 = "enterprise-frontend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

# -------------------------------------------------------------
# 2. Proveedor IAM OIDC para GitHub Actions
# -------------------------------------------------------------

# Certificado raíz TLS de GitHub Actions
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}

# -------------------------------------------------------------
# 3. Rol IAM y Política de Mínimo Privilegio para GitHub Actions
# -------------------------------------------------------------

# Política de confianza (Trust Relationship): Solo tu repo y ramas permitidas
data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Restringe el acceso estrictamente a tu repositorio
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}/${var.github_repo}:*"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "github-actions-ecr-role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json
}

# Permisos estrictos: Autenticación en ECR y subida/descarga de imágenes
data "aws_iam_policy_document" "ecr_push_policy" {
  statement {
    sid       = "ECRAuth"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "ECRManageImages"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload"
    ]
    resources = [
      aws_ecr_repository.backend.arn,
      aws_ecr_repository.frontend.arn
    ]
  }
}

resource "aws_iam_policy" "github_actions_ecr" {
  name        = "github-actions-ecr-policy"
  description = "Permisos mínimos para compilar y subir imágenes a ECR desde GitHub Actions"
  policy      = data.aws_iam_policy_document.ecr_push_policy.json
}

resource "aws_iam_role_policy_attachment" "github_actions_attach" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_ecr.arn
}