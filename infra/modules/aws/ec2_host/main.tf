locals {
  name_prefix      = "${var.environment}-${var.project_name}"
  open_webui_image = var.open_webui_image_uri
  ollama_image     = var.ollama_image_uri
  compose_file     = <<-EOF
    services:
      ollama:
        image: ${local.ollama_image}
        container_name: ollama
        ports:
          - "11434:11434"
        environment:
          OLLAMA_DEFAULT_MODEL: ${var.ollama_default_model}
        volumes:
          - ollama_data:/root/.ollama
        healthcheck:
          test: ["CMD", "ollama", "list"]
          interval: 30s
          timeout: 10s
          retries: 10
          start_period: 40s
        restart: unless-stopped

      open-webui:
        image: ${local.open_webui_image}
        container_name: open-webui
        depends_on:
          ollama:
            condition: service_healthy
        ports:
          - "3000:8080"
        environment:
          OLLAMA_BASE_URL: http://ollama:11434
          WEBUI_AUTH: "False"
        volumes:
          - open_webui_data:/app/backend/data
        restart: unless-stopped

    volumes:
      ollama_data:
      open_webui_data:
  EOF
}

resource "aws_iam_role" "instance" {
  name               = "${local.name_prefix}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy" "ecr_pull" {
  name   = "${local.name_prefix}-ecr-pull"
  role   = aws_iam_role.instance.id
  policy = data.aws_iam_policy_document.ecr_pull.json
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "this" {
  name = "${local.name_prefix}-ec2-profile"
  role = aws_iam_role.instance.name
}

resource "aws_security_group" "this" {
  name        = "${local.name_prefix}-web-sg"
  description = "Dev web access for ${local.name_prefix}"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Open WebUI"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = var.web_ingress_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "this" {
  ami                         = data.aws_ssm_parameter.amazon_linux.value
  instance_type               = var.instance_type
  iam_instance_profile        = aws_iam_instance_profile.this.name
  associate_public_ip_address = true
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.this.id]

  root_block_device {
    volume_size = var.root_volume_size_gb
    volume_type = "gp3"
  }

  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail
    dnf update -y
    dnf install -y awscli docker docker-compose-plugin
    systemctl enable --now docker
    systemctl enable --now amazon-ssm-agent
    usermod -aG docker ec2-user
    mkdir -p /opt/aws-llm-platform
    cat > /opt/aws-llm-platform/docker-compose.yml <<'COMPOSE'
    ${local.compose_file}
    COMPOSE
    registry="$(echo "${var.open_webui_image_uri}" | cut -d/ -f1)"
    aws ecr get-login-password --region "${var.aws_region}" | docker login --username AWS --password-stdin "$registry"
    cd /opt/aws-llm-platform
    docker compose pull
    docker compose up -d
    docker exec ollama ollama pull "${var.ollama_default_model}"
    chown -R ec2-user:ec2-user /opt/aws-llm-platform
  EOF
}

resource "aws_eip" "this" {
  domain   = "vpc"
  instance = aws_instance.this.id
}
