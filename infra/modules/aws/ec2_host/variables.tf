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

  default = ["192.168.1.1"]
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
  type      = string
  sensitive = true

  validation {
    condition = trimspace(var.ssh_public_key) == "" || can(regex(
      "^(ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521|sk-ssh-ed25519@openssh.com|sk-ecdsa-sha2-nistp256@openssh.com) [A-Za-z0-9+/=]+( .*)?$",
      trimspace(var.ssh_public_key),
    ))
    error_message = "ssh_public_key must be blank or a single-line OpenSSH public key such as the contents of ~/.ssh/id_ed25519.pub."
  }
}
