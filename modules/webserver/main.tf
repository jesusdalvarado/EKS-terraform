resource "kubernetes_deployment" "example" {
  metadata {
    name = "terraform-webserver-example"
    labels = {
      test = "MyExampleApp"
    }
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "HelloApp"
      }
    }

    template {
      metadata {
        labels = {
          app = "HelloApp"
        }
      }

      spec {
        container {
          image = var.docker_image
          name  = "example"
          port {
            container_port = 5000
          }
          env {
            name = "REDIS_URL"
            value = var.redis_url
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "webserver_load_balancer" { # Exposing ports to the internet
  metadata {
    name = "hello-webserver-example"
  }
  spec {
    selector = {
      app = kubernetes_deployment.example.spec.0.template.0.metadata.0.labels.app
    }

    port {
      target_port = 5000 # This is the port of the pod that will be exposed
      port        = 8080 # Exposing the port to the internet on port 8000
      node_port = 30000 # Exposing the port to the node/host (on all the nodes)
    }

    type = "LoadBalancer"
  }
}