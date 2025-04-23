output "vpc_id" {
  value = module.networking.vpc_id
}

output load_balancer_controller_role_arn {
  value = module.oidc.load_balancer_service_role_arn
}