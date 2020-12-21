terraform {
  backend "s3" {
    bucket  = "eks-remote-terraform-state"
    key     = "terraform.tfstate"
    encrypt = true
    region  = "us-west-2"
  }

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  profile = "default"
  region = var.AWS_REGION
}

resource "aws_iam_instance_profile" "eks_test_profile" {
  name = "eks_test_profile"
  role = aws_iam_role.role.name
}
data "aws_iam_policy_document" "default" {
	version = "2012-10-17"
	statement {
		actions = ["sts:AssumeRole"]
		effect = "Allow"
		principals {
			identifiers = ["ec2.amazonaws.com", "eks.amazonaws.com"]
			type = "Service"
		}
	}
}

resource "aws_iam_role" "role" {
  name  = "eks_test_role_terraform"
	assume_role_policy = data.aws_iam_policy_document.default.json
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role_policy_attachment" "test-attach-eks-cluster-policy" {
  role = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks-worker-node-policy" {
  role = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks-cni-policy" {
  role = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks-container-registry-readonly-policy" {
  role = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "example-amazon-eks-vpc-resource-controller" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

resource "aws_vpc" "main" {
  cidr_block            = "10.0.0.0/16"
  enable_dns_support    = true
  enable_dns_hostnames  = true

  tags = {
    Name = "main"
  }
}

resource "aws_subnet" "example1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"
  map_public_ip_on_launch = true

  tags = {
    # "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/cluster/eks_cluster_example" = "shared"
  }
}

resource "aws_subnet" "example2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2b"
  map_public_ip_on_launch = true

  tags = {
    "kubernetes.io/cluster/eks_cluster_example" = "shared"
  }
}

resource "aws_eks_cluster" "eks_cluster_example" {
  name     = "eks_cluster_example"
  role_arn = aws_iam_role.role.arn

  vpc_config {
    subnet_ids = [aws_subnet.example1.id, aws_subnet.example2.id]
    endpoint_private_access = true
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.test-attach,
    aws_iam_role_policy_attachment.test-attach-eks-cluster-policy,
  ]
}

output "endpoint" {
  value = aws_eks_cluster.eks_cluster_example.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.eks_cluster_example
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "r_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "main"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.example1.id
  route_table_id = aws_route_table.r_table.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.example2.id
  route_table_id = aws_route_table.r_table.id
}

resource "tls_private_key" "ssh" {
  algorithm   = "RSA"
  rsa_bits = "4096"
}
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = tls_private_key.ssh.public_key_openssh
}

resource "aws_eks_node_group" "example_node" {
  cluster_name    = aws_eks_cluster.eks_cluster_example.name
  node_group_name = "example_node1"
  node_role_arn   = aws_iam_role.role.arn
  subnet_ids      = [aws_subnet.example1.id, aws_subnet.example2.id]
  remote_access {
    ec2_ssh_key = aws_key_pair.deployer.id
  }

  scaling_config {
    desired_size  = 2
    max_size      = 2
    min_size      = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks-worker-node-policy,
    aws_iam_role_policy_attachment.eks-cni-policy,
    aws_iam_role_policy_attachment.eks-container-registry-readonly-policy,
    aws_internet_gateway.gw
  ]
}

module "my_flask_webserver" {
  source                                 = "./modules/webserver"
  docker_image                           = "ghcr.io/jesusdalvarado/simple-hello-world:latest"
  cluster_name                           = aws_eks_cluster.eks_cluster_example.name
  node_role_arn                          = aws_iam_role.role.arn
  subnet1_id                             = aws_subnet.example1.id
  subnet2_id                             = aws_subnet.example2.id
  ec2_ssh_key                            = aws_key_pair.deployer.id
  worker_node_policy                     = aws_iam_role_policy_attachment.eks-worker-node-policy
  eks_cni_policy                         = aws_iam_role_policy_attachment.eks-cni-policy
  eks_container_registry_readonly_policy = aws_iam_role_policy_attachment.eks-container-registry-readonly-policy
  aws_internet_gateway                   = aws_internet_gateway.gw
}
