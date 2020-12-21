variable "docker_image" {
  type        = string
  description = "Docker image to deploy the webserver"
}

variable "redis_url" {
  type        = string
  description = "Redis Url"
}