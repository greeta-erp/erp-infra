resource "kubernetes_config_map_v1" "mongodb" {
  metadata {
    name = "mongodb"
  }

  data = {
    "database-name" = "admin"
  }
}

resource "kubernetes_secret_v1" "mongodb" {
  metadata {
    name = "mongodb"
  }

  type = "Opaque"

  data = {
    "database-password" = "UGlvdF8xMjM="  # Base64-encoded password
    "database-user"     = "cGlvdHI="      # Base64-encoded username
  }
}

resource "kubernetes_deployment_v1" "mongodb" {
  depends_on = [null_resource.deploy_grafana_script]
  metadata {
    name = "mongodb"
    labels = {
      app = "mongodb"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "mongodb"
      }
    }

    template {
      metadata {
        labels = {
          app = "mongodb"
        }
      }

      spec {
        container {
          name  = "mongodb"
          image = "mongo:latest"

          port {
            container_port = 27017
          }

          env {
            name = "MONGO_INITDB_DATABASE"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map_v1.mongodb.metadata[0].name
                key  = "database-name"
              }
            }
          }

          env {
            name = "MONGO_INITDB_ROOT_USERNAME"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.mongodb.metadata[0].name
                key  = "database-user"
              }
            }
          }

          env {
            name = "MONGO_INITDB_ROOT_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.mongodb.metadata[0].name
                key  = "database-password"
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "mongodb" {
  metadata {
    name = "mongodb"
    labels = {
      app = "mongodb"
    }
  }

  spec {
    selector = {
      app = "mongodb"
    }

    port {
      port = 27017
      protocol = "TCP"
    }
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v1" "mongodb_hpa" {
  metadata {
    name = "mongodb-hpa"
  }
  spec {
    max_replicas = 2
    min_replicas = 1
    scale_target_ref {
      api_version = "apps/v1"
      kind = "Deployment"
      name = kubernetes_deployment_v1.mongodb.metadata[0].name 
    }
    target_cpu_utilization_percentage = 70
  }
}