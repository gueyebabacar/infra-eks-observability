# Makefile principal pour ton projet de migration EKS + GitOps

# Variables
TF_DIR = infra/terraform
KUBECONFIG ?= ~/.kube/config
AWS_REGION ?= eu-west-3
EKS_CLUSTER_NAME ?= devops-eks-cluster
ARGOCD_NAMESPACE = argocd

# Vérification des outils nécessaires
check-tools:
	@command -v terraform >/dev/null 2>&1 || { echo >&2 "Terraform est requis mais non installé. Abandon."; exit 1; }
	@command -v kubectl >/dev/null 2>&1 || { echo >&2 "Kubectl est requis mais non installé. Abandon."; exit 1; }
	@command -v aws >/dev/null 2>&1 || { echo >&2 "AWS CLI est requis mais non installé. Abandon."; exit 1; }

# Terraform Commands
.PHONY: init plan apply destroy

init: check-tools
	cd $(TF_DIR) && terraform init

plan: check-tools
	cd $(TF_DIR) && terraform plan

apply: check-tools
	cd $(TF_DIR) && terraform apply -auto-approve

destroy: check-tools
	cd $(TF_DIR) && terraform destroy -auto-approve

# Kubernetes / ArgoCD Installation
.PHONY: install-argocd

install-argocd: check-tools
	kubectl create namespace $(ARGOCD_NAMESPACE) || echo "Namespace $(ARGOCD_NAMESPACE) déjà existant."
	kubectl apply -n $(ARGOCD_NAMESPACE) -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Port-forward to ArgoCD UI
.PHONY: argocd-ui

argocd-ui: check-tools
	kubectl port-forward svc/argocd-server -n $(ARGOCD_NAMESPACE) 8080:443

# EKS update config
.PHONY: update-kubeconfig

update-kubeconfig: check-tools
	aws eks update-kubeconfig --region $(AWS_REGION) --name $(EKS_CLUSTER_NAME)

# Optionally, clean up the Kubeconfig if needed
.PHONY: clean-kubeconfig
clean-kubeconfig:
	rm -f $(KUBECONFIG)
	echo "Kubeconfig supprimé."
