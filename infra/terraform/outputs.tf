# infra/terraform/outputs.tf

output "cluster_name" {
  description = "Nom du cluster EKS"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint du cluster EKS"
  value       = module.eks.cluster_endpoint
}

output "vpc_id" {
  description = "ID du VPC"
  value       = module.vpc.vpc_id
}
