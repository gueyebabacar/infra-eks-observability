provider "aws" {
  region = var.region
}

# VPC
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "flask-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.region}a", "${var.region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    "kubernetes.io/cluster/flask-eks" = "shared"
  }
}

# EKS Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 18.0"

  cluster_name    = "flask-eks"
  cluster_version = "1.28" # Mise à jour vers une version supportée
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets

  # Groupes de nœuds gérés
  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.micro"]
      desired_size   = 2
      min_size       = 1
      max_size       = 3
    }
  }

  # Activer l'accès au control plane
  cluster_endpoint_public_access = true

  tags = {
    Environment = "dev"
  }
}

# ECR Repository
resource "aws_ecr_repository" "flask_app" {
  name                 = "flask-app"
  image_tag_mutability = "MUTABLE"
}

# DocumentDB
resource "aws_docdb_cluster" "docdb" {
  cluster_identifier      = "flask-docdb"
  engine                  = "docdb"
  master_username         = var.docdb_username # Changé à "flaskadmin" dans variables.tf
  master_password         = var.docdb_password
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_security_group.docdb_sg.id]
  db_subnet_group_name    = aws_docdb_subnet_group.docdb.name
}

resource "aws_docdb_subnet_group" "docdb" {
  name       = "flask-docdb-subnet-group"
  subnet_ids = module.vpc.private_subnets
}

resource "aws_security_group" "docdb_sg" {
  name        = "flask-docdb-sg"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = module.vpc.private_subnets_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# OpenSearch Service-Linked Role
resource "aws_iam_service_linked_role" "opensearch" {
  aws_service_name = "es.amazonaws.com"
  description      = "Service-linked role for OpenSearch"
}

# OpenSearch
resource "aws_opensearch_domain" "logs" {
  domain_name    = "flask-logs"
  engine_version = "OpenSearch_2.3"

  cluster_config {
    instance_type = "t3.small.search"
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 10
  }

  vpc_options {
    subnet_ids         = [module.vpc.private_subnets[0]]
    security_group_ids = [aws_security_group.opensearch_sg.id]
  }

  access_policies = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "es:*",
      "Resource": "arn:aws:es:${var.region}:${data.aws_caller_identity.current.account_id}:domain/flask-logs/*"
    }
  ]
}
POLICY

  depends_on = [aws_iam_service_linked_role.opensearch]
}

resource "aws_security_group" "opensearch_sg" {
  name        = "flask-opensearch-sg"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = module.vpc.private_subnets_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_caller_identity" "current" {}
