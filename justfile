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

destroy:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "{{PROJECT_DIR}}/infra/live/dev/aws"
    export AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
    terragrunt run-all --terragrunt-non-interactive --terragrunt-exclude-dir ./oidc destroy

apply:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "{{PROJECT_DIR}}/infra/live/dev/aws"
    export AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
    terragrunt run-all --terragrunt-non-interactive apply

plan:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "{{PROJECT_DIR}}/infra/live/dev/aws"
    export AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
    terragrunt run-all --terragrunt-non-interactive plan
