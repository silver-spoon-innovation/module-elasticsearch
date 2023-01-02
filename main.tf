provider "aws" {
  region = var.aws_region
  profile = var.aws_profile
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

resource "helm_release" "kube-elasticsearch-sssm" {
  name             = "elasticsearch-sssm"
  repository       = "https://helm.elastic.co"
  chart            = "elasticsearch"
  version          = "8.5.1"
  namespace        = kubernetes_namespace.ns-monitoring.metadata.0.name
  create_namespace = false

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