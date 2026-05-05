variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "devops"
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "employee-api"
}

variable "app_image" {
  description = "Docker image"
  type        = string
  default     = "employee-api:latest"
}

variable "replicas" {
  description = "Number of pod replicas"
  type        = number
  default     = 1
}
