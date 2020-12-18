variable "cluster_name" {
    type        = string
    description = "The name of the cluster"
}

variable "node_role_arn" {
  type        = string
  description = "Node Role ARN"
}

variable "subnet1_id" {
  type        = string
  description = "Id of subnet1"
}

variable "subnet2_id" {
  type        = string
  description = "Id of subnet2"
}

variable "ec2_ssh_key" {
  type        = string
  description = "SSH key for remote access"
}

variable "worker_node_policy" {
  description = "Worker Node Policy"
}

variable "eks_cni_policy" {
  description = "EKS CNI Policy"
}

variable "eks_container_registry_readonly_policy" {
  description = "EKS Container Registry Read Only Policy"
}

variable "aws_internet_gateway" {
  description = "Internet Gateway"
}

variable "docker_image" {
    type        = string
    description = "Docker image to deploy the webserver"
}
