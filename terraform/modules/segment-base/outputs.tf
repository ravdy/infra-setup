
output "eks_cluster_id" {
  value = module.env-segment.eks_cluster_id
}
output "eks_cluster_ca_certificate" {
  value = module.env-segment.eks_cluster_ca_certificate
}

output "eks_cluster_endpoint" {
  value = module.env-segment.eks_cluster_endpoint
}

output "eks_node_role_arn" {
  value = module.env-segment.eks_node_role_arn
}

output "internal_dns_id" {
  value = module.env-segment.internal_dns_id
}

