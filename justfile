default:
    @just --list

check-space:
    @bash -eu -c '\
        required_host_kb=5242880; \
        required_host_label="5 GiB"; \
        available_host_kb="$(df -Pk . | awk '\''NR==2 {print $4}'\'')"; \
        available_host_label="$(awk -v kb="$available_host_kb" '\''BEGIN {printf "%.1f GiB", kb / 1024 / 1024}'\'')"; \
        if [ "$available_host_kb" -lt "$required_host_kb" ]; then \
            echo "Not enough disk space to pull and start the Docker stack."; \
            echo "Required host free space: at least $required_host_label."; \
            echo "Available host free space: $available_host_label."; \
            echo "Free up disk space before running docker compose pull."; \
            exit 1; \
        fi; \
        echo "Host disk space check passed for the Docker stack."; \
        echo "Required host free space: $required_host_label."; \
        echo "Available host free space: $available_host_label."; \
        docker_settings_path="$HOME/Library/Group Containers/group.com.docker/settings-store.json"; \
        docker_raw_path="$HOME/Library/Containers/com.docker.docker/Data/vms/0/data/Docker.raw"; \
        model="$(docker compose config | sed -n '\''s/^[[:space:]]*OLLAMA_DEFAULT_MODEL: //p'\'' | head -n1)"; \
        case "$model" in \
            qwen2.5-coder:3b) required_docker_bytes=$((10 * 1024 * 1024 * 1024)); required_docker_label="10 GiB";; \
            qwen2.5-coder:7b|llama3.1:8b) required_docker_bytes=$((12 * 1024 * 1024 * 1024)); required_docker_label="12 GiB";; \
            tinyllama) required_docker_bytes=$((8 * 1024 * 1024 * 1024)); required_docker_label="8 GiB";; \
            *) required_docker_bytes=$((10 * 1024 * 1024 * 1024)); required_docker_label="10 GiB";; \
        esac; \
        if [ -f "$docker_settings_path" ] && [ -f "$docker_raw_path" ]; then \
            docker_disk_mib="$(sed -n '\''s/.*"DiskSizeMiB":[[:space:]]*\([0-9][0-9]*\).*/\1/p'\'' "$docker_settings_path" | head -n1)"; \
            docker_alloc_blocks="$(stat -f %b "$docker_raw_path")"; \
            if [ -n "$docker_disk_mib" ] && [ -n "$docker_alloc_blocks" ]; then \
                docker_limit_bytes=$((docker_disk_mib * 1024 * 1024)); \
                docker_alloc_bytes=$((docker_alloc_blocks * 512)); \
                docker_free_bytes=$((docker_limit_bytes - docker_alloc_bytes)); \
                if [ "$docker_free_bytes" -lt 0 ]; then \
                    docker_free_bytes=0; \
                fi; \
                docker_free_label="$(awk -v bytes="$docker_free_bytes" '\''BEGIN {printf "%.1f GiB", bytes / 1024 / 1024 / 1024}'\'')"; \
                if [ "$docker_free_bytes" -lt "$required_docker_bytes" ]; then \
                    echo "Docker Desktop disk image is too full for a safe docker compose pull."; \
                    echo "Required estimated free space inside Docker Desktop: at least $required_docker_label."; \
                    echo "Estimated free space inside Docker Desktop: $docker_free_label."; \
                    echo "Increase Docker Desktop disk size or reclaim space before retrying."; \
                    exit 1; \
                fi; \
                echo "Docker Desktop disk check passed."; \
                echo "Required estimated free space inside Docker Desktop: $required_docker_label."; \
                echo "Estimated free space inside Docker Desktop: $docker_free_label."; \
            fi; \
        fi; \
    '

start: check-space
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
