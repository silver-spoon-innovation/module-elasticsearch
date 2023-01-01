provider "aws" {
  region = var.aws_region
  profile = "default"
}

provider "kubernetes" {
  cluster_ca_certificate = base64decode(var.kubernetes_cluster_cert_data)
  host                   = var.kubernetes_cluster_endpoint
  exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", var.kubernetes_cluster_name]
      command     = "aws"
    }
}

provider "helm" {
  kubernetes {
    cluster_ca_certificate = base64decode(var.kubernetes_cluster_cert_data)
    host                   = var.kubernetes_cluster_endpoint
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", var.kubernetes_cluster_name]
      command     = "aws"
    }
  }
}

resource "kubernetes_namespace" "ns-monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "helm_release" "kube-prometheus-sssm" {
  name             = "elasticsearch-sssm"
  repository       = "https://helm.elastic.co"
  chart            = "elasticsearch"
  version          = "8.5.1"
  namespace        = kubernetes_namespace.ns-monitoring.metadata.0.name
  create_namespace = false
  timeout          = 1500 

  set {
    name  = "secret.enabled"
    value = "true"
  }
  set {
    name  = "secret.password"
    value = "sssmdevsearch"
  }

  set {
    name = "antiAffinity"
    value = "soft"
  }

}