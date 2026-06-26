locals {
  deploy_branches       = ["main"]
  force_delete          = true
  image_expiration_days = 30
  instance_type         = "t3.xlarge"
  root_volume_size_gb   = 80
  ollama_default_model  = "qwen2.5-coder:3b"
  web_ingress_cidrs     = []
  default_ssh_public_key_path = pathexpand("~/.ssh/id_ed25519.pub")
  ssh_public_key              = get_env(
    "SSH_PUBLIC_KEY",
    fileexists(local.default_ssh_public_key_path) ? trimspace(file(local.default_ssh_public_key_path)) : "",
  )
}

inputs = {
  deploy_branches       = local.deploy_branches
  force_delete          = local.force_delete
  image_expiration_days = local.image_expiration_days
  instance_type         = local.instance_type
  root_volume_size_gb   = local.root_volume_size_gb
  ollama_default_model  = local.ollama_default_model
  web_ingress_cidrs     = local.web_ingress_cidrs
  ssh_public_key        = local.ssh_public_key
}
