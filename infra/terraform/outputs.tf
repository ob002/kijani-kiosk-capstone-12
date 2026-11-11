output "staging_namespace" {
  description = "Name of the staging namespace"
  value       = kubernetes_namespace.staging.metadata[0].name
}

output "production_namespace" {
  description = "Name of the production namespace"
  value       = kubernetes_namespace.production.metadata[0].name
}
