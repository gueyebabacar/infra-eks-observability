output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_id
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.flask_app.repository_url
}

output "docdb_endpoint" {
  description = "DocumentDB endpoint"
  value       = aws_docdb_cluster.docdb.endpoint
}

output "opensearch_endpoint" {
  description = "OpenSearch endpoint"
  value       = aws_opensearch_domain.logs.endpoint
}
