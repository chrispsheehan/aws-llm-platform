variable "aws_region" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "root_volume_size_gb" {
  type = number
}

variable "web_ingress_cidrs" {
  type = list(string)
}

variable "ollama_default_model" {
  type = string
}

variable "open_webui_image_uri" {
  type = string
}

variable "ollama_image_uri" {
  type = string
}

variable "ssh_public_key" {
  type = string
}
