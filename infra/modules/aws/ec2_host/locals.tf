locals {
  name_prefix                 = "${var.environment}-${var.project_name}"
  # do it like thi https://github.com/chrispsheehan/aws-argocd/blob/main/tf/main.tf#L76
  effective_web_ingress_cidrs = length(var.web_ingress_cidrs) > 0 ? var.web_ingress_cidrs : ["${trimspace(data.http.public_ip.response_body)}/32"]
  ssh_enabled                 = trimspace(var.ssh_public_key) != ""
  compose_object = {
    services = {
      ollama = {
        image          = var.ollama_image_uri
        container_name = "ollama"
        ports          = ["11434:11434"]
        environment = {
          OLLAMA_DEFAULT_MODEL = var.ollama_default_model
        }
        volumes = ["ollama_data:/root/.ollama"]
        healthcheck = {
          test         = ["CMD", "ollama", "list"]
          interval     = "30s"
          timeout      = "10s"
          retries      = 10
          start_period = "40s"
        }
        restart = "unless-stopped"
      }
      open-webui = {
        image          = var.open_webui_image_uri
        container_name = "open-webui"
        depends_on = {
          ollama = {
            condition = "service_healthy"
          }
        }
        ports = ["3000:8080"]
        environment = {
          OLLAMA_BASE_URL = "http://ollama:11434"
          WEBUI_AUTH      = "False"
        }
        volumes = ["open_webui_data:/app/backend/data"]
        restart = "unless-stopped"
      }
    }
    volumes = {
      ollama_data     = {}
      open_webui_data = {}
    }
  }
  compose_file = yamlencode(local.compose_object)
  user_data_lines = [
    "#!/bin/bash",
    "set -euxo pipefail",
    "dnf update -y",
    "dnf install -y awscli docker docker-compose-plugin",
    "systemctl enable --now docker",
    "systemctl enable --now amazon-ssm-agent",
    "usermod -aG docker ec2-user",
    "mkdir -p /opt/aws-llm-platform",
    "cat > /opt/aws-llm-platform/docker-compose.yml <<'COMPOSE'",
    local.compose_file,
    "COMPOSE",
    "registry=\"$(echo \"${var.open_webui_image_uri}\" | cut -d/ -f1)\"",
    "aws ecr get-login-password --region \"${var.aws_region}\" | docker login --username AWS --password-stdin \"$registry\"",
    "cd /opt/aws-llm-platform",
    "docker compose pull",
    "docker compose up -d",
    "docker exec ollama ollama pull \"${var.ollama_default_model}\"",
    "chown -R ec2-user:ec2-user /opt/aws-llm-platform",
  ]
  user_data = join("\n", local.user_data_lines)
}
