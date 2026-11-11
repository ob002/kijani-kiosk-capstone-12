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
