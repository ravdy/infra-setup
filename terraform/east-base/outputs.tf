output "eks_cluster_id" {
  value = module.segment_east.eks_cluster_id
}
output "eks_cluster_ca_certificate" {
  value = module.segment_east.eks_cluster_ca_certificate
}
output "eks_cluster_endpoint" {
  value = module.segment_east.eks_cluster_endpoint
}

output "eks_node_role_arn" {
  value = module.segment_east.eks_node_role_arn
}

output "internal_dns_id" {
  value = module.segment_east.internal_dns_id
}
