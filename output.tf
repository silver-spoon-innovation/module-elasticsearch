output "logging_namespace" {
    value = kubernetes_namespace.ns-logging.metadata.0.name
}