include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependencies {
  paths = ["../oidc"]
}

terraform {
  source = "../../../../modules//aws//ecr"
}

inputs = {
  repository_name = "aws-llm-platform-dev"
  images = {
    open_webui = {
      source_image = "ghcr.io/open-webui/open-webui"
      source_tag   = "main"
      target_tag   = "open-webui-current"
    }
    ollama = {
      source_image = "ollama/ollama"
      source_tag   = "latest"
      target_tag   = "ollama-current"
    }
  }
}
