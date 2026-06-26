include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "ecr" {
  config_path = "${get_original_terragrunt_dir()}/../ecr"

  mock_outputs = {
    image_uris = {
      open_webui = "000000000000.dkr.ecr.eu-west-2.amazonaws.com/aws-llm-platform-dev:open-webui-current"
      ollama     = "000000000000.dkr.ecr.eu-west-2.amazonaws.com/aws-llm-platform-dev:ollama-current"
    }
  }

  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "destroy", "init", "show", "graph-dependencies"]
}

dependencies {
  paths = ["../oidc", "../ecr"]
}

terraform {
  source = "../../../../modules//aws//ec2_host"
}

inputs = {
  open_webui_image_uri = dependency.ecr.outputs.image_uris.open_webui
  ollama_image_uri     = dependency.ecr.outputs.image_uris.ollama
}
