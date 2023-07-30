resource "kubernetes_deployment_v1" "movie_ui_deployment" {
  depends_on = [kubernetes_deployment_v1.movie_deployment]
  metadata {
    name = "movie-ui"
    labels = {
      app = "movie-ui"
    }
  }
 
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "movie-ui"
      }
    }
    template {
      metadata {
        labels = {
          app = "movie-ui"
        }
      }
      spec {
        container {
          image = "ghcr.io/greeta-erp/erp-ui"
          name  = "movie-ui"
          image_pull_policy = "Always"
          port {
            container_port = 4200
          }                                                                                          
        }
      }
    }
  }
}

# Resource: Keycloak Server Horizontal Pod Autoscaler
resource "kubernetes_horizontal_pod_autoscaler_v1" "movie_ui_hpa" {
  metadata {
    name = "movie-ui-hpa"
  }
  spec {
    max_replicas = 2
    min_replicas = 1
    scale_target_ref {
      api_version = "apps/v1"
      kind = "Deployment"
      name = kubernetes_deployment_v1.movie_ui_deployment.metadata[0].name
    }
    target_cpu_utilization_percentage = 50
  }
}

resource "kubernetes_service_v1" "movie_ui_service" {
  metadata {
    name = "movie-ui"
  }
  spec {
    selector = {
      app = "movie-ui"
    }
    port {
      port = 4200
    }
  }
}
