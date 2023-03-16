provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

provider "kubernetes" {
  cluster_ca_certificate = base64decode(var.kubernetes_cluster_cert_data)
  host                   = var.kubernetes_cluster_endpoint
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", var.kubernetes_cluster_name, "--profile", var.aws_profile]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    cluster_ca_certificate = base64decode(var.kubernetes_cluster_cert_data)
    host                   = var.kubernetes_cluster_endpoint
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", var.kubernetes_cluster_name, "--profile", var.aws_profile]
      command     = "aws"
    }
  }
}

resource "kubernetes_namespace" "ns-logging" {
  metadata {
    name = "logging"
  }
}

resource "helm_release" "kube-elasticsearch-sssm" {
  name             = "elasticsearch-sssm"
  repository       = "https://helm.elastic.co"
  chart            = "elasticsearch"
  version          = "8.5.1"
  namespace        = kubernetes_namespace.ns-logging.metadata.0.name
  create_namespace = false

  set {
    name  = "replicas"
    value = 2
  }
  set {
    name  = "minimumMasterNodes"
    value = 1
  }

  set {
    name  = "resources.requests.memory"
    value = "1Gi"
  }

  set {
    name  = "resources.limits.memory"
    value = "1Gi"
  }
}

resource "helm_release" "kube-logstash-sssm" {
  name             = "logstash-sssm"
  repository       = "https://helm.elastic.co"
  chart            = "logstash"
  version          = "8.5.1"
  namespace        = kubernetes_namespace.ns-logging.metadata.0.name
  create_namespace = false

  values = [
    file("${path.module}/values-files/logstash-values.yaml")
  ]
}

resource "helm_release" "kube-filebeat-sssm" {
  name             = "filebeat-sssm"
  repository       = "https://helm.elastic.co"
  chart            = "filebeat"
  version          = "8.5.1"
  namespace        = kubernetes_namespace.ns-logging.metadata.0.name
  create_namespace = false

  values = [
    file("${path.module}/values-files/filebeat-values.yaml")
  ]
}

resource "helm_release" "kube-kibana-sssm" {
  name             = "kibana-sssm"
  repository       = "https://helm.elastic.co"
  chart            = "kibana"
  version          = "8.5.1"
  namespace        = kubernetes_namespace.ns-logging.metadata.0.name
  create_namespace = false

  set {
    name  = "resources.requests.cpu"
    value = "50m"
  }
  set {
    name  = "resources.requests.memory"
    value = "1Gi"
  }

  set {
    name  = "resources.limits.cpu"
    value = "50m"
  }

  set {
    name  = "resources.limits.memory"
    value = "1Gi"
  }
}
