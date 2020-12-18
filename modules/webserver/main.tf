resource "aws_eks_node_group" "example_node" {
  cluster_name    = var.cluster_name
  node_group_name = "example_node1"
  node_role_arn   = var.node_role_arn
  subnet_ids      = [var.subnet1_id, var.subnet2_id]
  remote_access {
    ec2_ssh_key = var.ec2_ssh_key
  }

  scaling_config {
    desired_size  = 2
    max_size      = 2
    min_size      = 1
  }

  depends_on = [
    var.worker_node_policy,
    var.eks_cni_policy,
    var.eks_container_registry_readonly_policy,
    var.aws_internet_gateway
  ]
}

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