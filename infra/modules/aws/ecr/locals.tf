locals {
  seeded_source_images = {
    for key, image in var.images :
    key => "${image.source_image}:${image.source_tag}"
  }
  seeded_image_uris = {
    for key, image in var.images :
    key => "${aws_ecr_repository.this.repository_url}:${image.target_tag}"
  }
}
