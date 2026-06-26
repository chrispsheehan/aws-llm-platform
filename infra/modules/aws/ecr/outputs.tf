output "repository_name" {
  value = aws_ecr_repository.this.name
}

output "repository_url" {
  value = aws_ecr_repository.this.repository_url
}

output "repository_arn" {
  value = aws_ecr_repository.this.arn
}

output "image_uris" {
  value = {
    for key, image in var.images :
    key => "${aws_ecr_repository.this.repository_url}:${image.target_tag}"
  }
}
