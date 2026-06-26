locals {
  deploy_branches       = ["main"]
  force_delete          = true
  image_expiration_days = 30
  instance_type         = "t3.xlarge"
  root_volume_size_gb   = 80
  ollama_default_model  = "qwen2.5-coder:3b"
}

inputs = {
  deploy_branches       = local.deploy_branches
  force_delete          = local.force_delete
  image_expiration_days = local.image_expiration_days
  instance_type         = local.instance_type
  root_volume_size_gb   = local.root_volume_size_gb
  ollama_default_model  = local.ollama_default_model
}
