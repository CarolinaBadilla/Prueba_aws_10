module "load_balancer_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "enterprise-dev-aws-lbc-role"

  role_policy_arns = {
    policy = "arn:aws:iam::512902043510:policy/AWSLoadBalancerControllerIAMPolicy"
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

output "lbc_role_arn" {
  value = module.load_balancer_controller_irsa.iam_role_arn
}