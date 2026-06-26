default:
    @just --list

PROJECT_DIR := justfile_directory()

start:
    @bash -eu -c '\
        model="$(docker compose config | sed -n '\''s/^[[:space:]]*OLLAMA_DEFAULT_MODEL: //p'\'' | head -n1)"; \
        if [ -z "$model" ]; then \
            echo "Could not determine OLLAMA_DEFAULT_MODEL from docker-compose.yml."; \
            exit 1; \
        fi; \
        docker compose pull; \
        docker compose up -d; \
        echo "Pulling Ollama model: $model"; \
        docker exec ollama ollama pull "$model"; \
        echo "Available Ollama models:"; \
        docker exec ollama ollama list; \
        echo "Opening http://localhost:3000"; \
        open http://localhost:3000; \
    '

# Run Terraform and Terragrunt formatting locally.
format:
    #!/usr/bin/env bash
    terraform fmt -recursive
    terragrunt hclfmt

setup:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "{{PROJECT_DIR}}/infra/live/dev/aws/oidc"
    export AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
    terragrunt --terragrunt-non-interactive apply

destroy:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "{{PROJECT_DIR}}/infra/live/dev/aws"
    export AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
    terragrunt run-all --terragrunt-non-interactive --terragrunt-exclude-dir ./oidc destroy

apply:
    #!/usr/bin/env bash
    set -euo pipefail
    ssh_public_key_path="${SSH_PUBLIC_KEY_PATH:-$HOME/.ssh/id_ed25519.pub}"
    if [[ -z "${TF_VAR_ssh_public_key:-}" && -f "${ssh_public_key_path}" ]]; then
        export TF_VAR_ssh_public_key="$(tr -d '\n' < "${ssh_public_key_path}")"
    fi
    cd "{{PROJECT_DIR}}/infra/live/dev/aws"
    export AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
    terragrunt run-all --terragrunt-non-interactive apply

plan:
    #!/usr/bin/env bash
    set -euo pipefail
    ssh_public_key_path="${SSH_PUBLIC_KEY_PATH:-$HOME/.ssh/id_ed25519.pub}"
    if [[ -z "${TF_VAR_ssh_public_key:-}" && -f "${ssh_public_key_path}" ]]; then
        export TF_VAR_ssh_public_key="$(tr -d '\n' < "${ssh_public_key_path}")"
    fi
    cd "{{PROJECT_DIR}}/infra/live/dev/aws"
    export AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
    terragrunt run-all --terragrunt-non-interactive plan

ssh:
    #!/usr/bin/env bash
    set -euo pipefail
    ssh_key_path="${SSH_KEY_PATH:-$HOME/.ssh/id_ed25519}"
    if [[ ! -f "${ssh_key_path}" ]]; then
        echo "SSH private key not found at ${ssh_key_path}." >&2
        exit 1
    fi
    cd "{{PROJECT_DIR}}/infra/live/dev/aws/ec2_host"
    export AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
    public_ip="$(terragrunt output -raw public_ip)"
    exec ssh \
        -i "${ssh_key_path}" \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        "ec2-user@${public_ip}"
