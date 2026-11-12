terraform {
  required_version = ">= 1.7.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "minikube"
}

resource "kubernetes_namespace" "staging" {
  metadata {
    name = "kijani-staging"
    labels = {
      env     = "staging"
      project = "kijani-kiosk"
    }
  }

  # Ansible (infra/ansible/configure-staging.yml) adds configured-by=ansible
  # after Terraform creates the namespace. Without this, every terraform
  # apply would strip that label: two tools fighting over one field.
  lifecycle {
    ignore_changes = [metadata[0].labels["configured-by"]]
  }
}

resource "kubernetes_namespace" "production" {
  metadata {
    name = "kijani-production"
    labels = {
      env     = "production"
      project = "kijani-kiosk"
    }
  }
}
