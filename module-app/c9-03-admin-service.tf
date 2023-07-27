resource "kubernetes_config_map_v1" "admin" {
  metadata {
    name      = "admin"
    labels = {
      app = "admin"
    }
  }

  data = {
    "application.yml" = file("${path.module}/app-conf/admin.yml")
  }
}


resource "kubernetes_deployment_v1" "admin_deployment" {
  depends_on = [kubernetes_deployment_v1.mongodb]
  metadata {
    name = "admin"
    labels = {
      app = "admin"
    }
  }
 
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "admin"
      }
    }
    template {
      metadata {
        labels = {
          app = "admin"
        }
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/path"   = "/actuator/prometheus"
          "prometheus.io/port"   = "8080"
        }        
      }

      spec {

        service_account_name = "spring-cloud-kubernetes"         
        
        container {
          image = "ghcr.io/greeta-erp/admin-service:3798629177c912b17fc491fe509e84b39efed088"
          name  = "admin"
          image_pull_policy = "Always"

          port {
            container_port = 8080
          }

          env {
            name  = "SPRING_CLOUD_BOOTSTRAP_ENABLED"
            value = "true"
          } 

          # resources {
          #   requests = {
          #     memory = "756Mi"
          #     cpu    = "0.1"
          #   }
          #   limits = {
          #     memory = "756Mi"
          #     cpu    = "2"
          #   }
          # }

          lifecycle {
            pre_stop {
              exec {
                command = ["sh", "-c", "sleep 5"]
              }
            }
          }
          
          # liveness_probe {
          #   http_get {
          #     path = "/actuator/health/liveness"
          #     port = 8080
          #   }
          #   initial_delay_seconds = 120
          #   period_seconds        = 15
          # }

          # readiness_probe {
          #   http_get {
          #     path = "/actuator/health/readiness"
          #     port = 8080
          #   }
          #   initial_delay_seconds = 20
          #   period_seconds        = 15
          # }      
                               
        }
      }
    }
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v1" "admin_hpa" {
  metadata {
    name = "admin-hpa"
  }
  spec {
    max_replicas = 2
    min_replicas = 1
    scale_target_ref {
      api_version = "apps/v1"
      kind = "Deployment"
      name = kubernetes_deployment_v1.admin_deployment.metadata[0].name 
    }
    target_cpu_utilization_percentage = 70
  }
}

resource "kubernetes_service_v1" "admin_service" {
  metadata {
    name = "admin"
  }
  spec {
    selector = {
      app = "admin"
    }
    port {
      port = 8080
    }
  }
}
