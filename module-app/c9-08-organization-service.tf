resource "kubernetes_config_map_v1" "organization" {
  metadata {
    name      = "organization"
    labels = {
      app = "organization"
    }
  }

  data = {
    "application.properties" = file("${path.module}/app-conf/organization.properties")
  }
}

resource "kubernetes_secret_v1" "organization" {
  metadata {
    name = "organization"
  }

  data = {
    "spring.data.mongodb.password" = "UGlvdF8xMjM="
    "spring.data.mongodb.username" = "cGlvdHI="
  }

  type = "Opaque"
}


resource "kubernetes_deployment_v1" "organization_deployment" {
  depends_on = [kubernetes_deployment_v1.mongodb]
  metadata {
    name = "organization"
    labels = {
      app = "organization"
    }
  }
 
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "organization"
      }
    }
    template {
      metadata {
        labels = {
          app = "organization"
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
          image = "ghcr.io/greeta-erp/organization-service:53c854c42874bbc2dea85a51192c9112579e3630"
          name  = "organization"
          image_pull_policy = "Always"
          
          port {
            container_port = 8080
          }

          env {
            name  = "SPRING_CLOUD_BOOTSTRAP_ENABLED"
            value = "true"
          }

          env {
            name  = "SPRING_CLOUD_KUBERNETES_SECRETS_ENABLEAPI"
            value = "true"
          }

          env {
            name  = "JAVA_TOOL_OPTIONS"
            value = "-javaagent:/workspace/BOOT-INF/lib/opentelemetry-javaagent-1.17.0.jar"
          }

          env {
            name  = "OTEL_SERVICE_NAME"
            value = "organization"
          }

          env {
            name  = "OTEL_EXPORTER_OTLP_ENDPOINT"
            value = "http://tempo.observability-stack.svc.cluster.local:4317"
          }

          env {
            name  = "OTEL_METRICS_EXPORTER"
            value = "none"
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

resource "kubernetes_horizontal_pod_autoscaler_v1" "organization_hpa" {
  metadata {
    name = "organization-hpa"
  }
  spec {
    max_replicas = 2
    min_replicas = 1
    scale_target_ref {
      api_version = "apps/v1"
      kind = "Deployment"
      name = kubernetes_deployment_v1.organization_deployment.metadata[0].name 
    }
    target_cpu_utilization_percentage = 70
  }
}

resource "kubernetes_service_v1" "organization_service" {
  metadata {
    name = "organization"
    labels = {
      app = "organization"
      spring-boot = "true"
    }
  }
  spec {
    selector = {
      app = "organization"
    }
    port {
      port = 8080
    }
  }
}
