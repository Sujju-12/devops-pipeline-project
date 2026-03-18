output "namespace_created" {
  value = kubernetes_namespace.devops.metadata[0].name
}

output "deployment_name" {
  value = kubernetes_deployment.employee_api.metadata[0].name
}

output "replicas" {
  value = var.replicas
}

output "useful_commands" {
  value = <<-EOT
    kubectl get pods -n ${var.namespace}
    kubectl get svc  -n ${var.namespace}
    kubectl logs -l app=${var.app_name} -n ${var.namespace}
    minikube service ${var.app_name}-service -n ${var.namespace} --url
  EOT
}
