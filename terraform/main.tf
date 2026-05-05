# ── NAMESPACE ──────────────────────────────
resource "kubernetes_namespace" "devops" {
  metadata {
    name = var.namespace
    labels = {
      project    = "devops-pipeline"
      managed-by = "terraform"
    }
  }
}

# ── RESOURCE QUOTA ─────────────────────────
resource "kubernetes_resource_quota" "devops_quota" {
  metadata {
    name      = "devops-quota"
    namespace = kubernetes_namespace.devops.metadata[0].name
  }
  spec {
    hard = {
      "requests.cpu"    = "2"
      "requests.memory" = "2Gi"
      "limits.cpu"      = "4"
      "limits.memory"   = "4Gi"
      "pods"            = "10"
    }
  }
}

# ── CONFIG MAP ─────────────────────────────
resource "kubernetes_config_map" "app_config" {
  metadata {
    name      = "${var.app_name}-config"
    namespace = kubernetes_namespace.devops.metadata[0].name
  }
  data = {
    APP_NAME        = var.app_name
    SERVER_PORT     = "8080"
    SPRING_PROFILES_ACTIVE = "default"
    LOG_LEVEL       = "INFO"
  }
}

# ── DEPLOYMENT ─────────────────────────────
resource "kubernetes_deployment" "employee_api" {
  metadata {
    name      = var.app_name
    namespace = kubernetes_namespace.devops.metadata[0].name
    labels    = { app = var.app_name }
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = { app = var.app_name }
    }

    template {
      metadata {
        labels = { app = var.app_name }
      }

      spec {
        container {
          name              = var.app_name
          image             = var.app_image
          image_pull_policy = "IfNotPresent"

          port {
            container_port = 8080
          }

          resources {
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.app_config.metadata[0].name
            }
          }

          # ✅ FIX: app takes 30s to start — give it 90s before first check
          liveness_probe {
            http_get {
              path = "/actuator/health"
              port = 8080
            }
            initial_delay_seconds = 90
            period_seconds        = 15
            failure_threshold     = 3
            timeout_seconds       = 5
          }

          readiness_probe {
            http_get {
              path = "/actuator/health"
              port = 8080
            }
            initial_delay_seconds = 60
            period_seconds        = 10
            failure_threshold     = 3
            timeout_seconds       = 5
          }
        }
      }
    }
  }
}

# ── SERVICE ────────────────────────────────
resource "kubernetes_service" "employee_api" {
  metadata {
    name      = "${var.app_name}-service"
    namespace = kubernetes_namespace.devops.metadata[0].name
  }
  spec {
    selector = { app = var.app_name }
    type     = "NodePort"
    port {
      port        = 80
      target_port = 8080
      node_port   = 30080
    }
  }
}
