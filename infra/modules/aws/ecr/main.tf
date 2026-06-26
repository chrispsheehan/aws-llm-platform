resource "aws_ecr_repository" "this" {
  name         = var.repository_name
  force_delete = var.force_delete

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  count = var.image_expiration_days > 0 ? 1 : 0

  repository = aws_ecr_repository.this.name
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire images older than the configured retention"
        selection = {
          tagStatus   = "any"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.image_expiration_days
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

provider "docker" {
  registry_auth {
    address  = data.aws_ecr_authorization_token.this.proxy_endpoint
    username = data.aws_ecr_authorization_token.this.user_name
    password = data.aws_ecr_authorization_token.this.password
  }
}

resource "docker_image" "seeded" {
  for_each     = var.images
  name         = local.seeded_source_images[each.key]
  keep_locally = false
}

resource "docker_tag" "seeded" {
  for_each     = var.images
  source_image = docker_image.seeded[each.key].name
  target_image = local.seeded_image_uris[each.key]
}

resource "docker_registry_image" "seeded" {
  for_each = var.images
  name     = docker_tag.seeded[each.key].target_image
}
