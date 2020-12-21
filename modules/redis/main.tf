resource "kubernetes_deployment" "redis_deploy" {
  metadata {
    name = "terraform-redis-example"
    labels = {
      test = "MyRedisApp"
    }
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "RedisApp"
      }
    }

    template {
      metadata {
        labels = {
          app = "RedisApp"
        }
      }

      spec {
        container {
          image = var.docker_image
          name  = "example"
          port {
            container_port = 6379
          }
        }
      }
    }
  }
}

output "redis_deployment" {
  value = kubernetes_deployment.redis_deploy
}

resource "kubernetes_service" "redis_load_balancer" { # Exposing ports to the internet
  metadata {
    name = "redis-example"
  }
  spec {
    selector = {
      app = kubernetes_deployment.redis_deploy.spec.0.template.0.metadata.0.labels.app
    }

    port {
      target_port = 6379 # This is the port of the pod that will be exposed
      port        = 6379 # Exposing the port to the internet on port 6379
      node_port   = 30001 # Exposing the port to the node/host (on all the nodes)
    }

    type = "LoadBalancer"
  }
}
