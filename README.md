# Local Open-Source LLM Chat

This repo includes a Docker Compose stack for a fully self-hosted chat UI using:

- `Open WebUI` for the chat interface
- `Ollama` for local model serving
- `qwen2.5-coder:3b` as the default model configured in Compose for a better small local coding model

Start it with:

```bash
just start
```

Then open `http://localhost:3000`.

Notes:

- `just start` runs `docker compose pull`, starts the containers, then pulls the Ollama model configured by `OLLAMA_DEFAULT_MODEL`, lists the available Ollama models, and opens `http://localhost:3000` on macOS.
- `just start` automatically downloads the Ollama model configured by `OLLAMA_DEFAULT_MODEL` into the `ollama` container.
- `WEBUI_AUTH` is disabled for local use. Turn it on before exposing this outside your machine.
- If you want a different default model later, change `OLLAMA_DEFAULT_MODEL` in `docker-compose.yml`.

## Dev AWS Infra

This repo also includes a dev-only Terragrunt scaffold, guided by
`aws-terragrunt-starter`, for a single `EC2` Docker host backed by private
`ECR` repositories.

Included stacks:

- `aws/oidc`
- `aws/ecr`
- `aws/ec2_host`

Useful commands:

```bash
just tg dev apply
just destroy
```

Bootstrap and workflow details live in [infra/README.md](infra/README.md).
The dev `EC2` ingress is IP-restricted by default. When `web_ingress_cidrs` is
empty, Terraform resolves the current public IP from `https://checkip.amazonaws.com`
and applies it as a `/32`.

## EC2 sizing

For a self-hosted coding assistant with `open-webui`, `ollama`, and `qwen2.5-coder:3b`, these are the practical EC2 starting points in `us-east-1`:

- `S` - `m7g.large` - cheapest possible experiment - `2 vCPU`, `8 GiB RAM` - about `$0.0816/hr` and `$1.96/day`
- `M` - `m7g.xlarge` - recommended minimum for realistic Codex-like CLI experimentation - `4 vCPU`, `16 GiB RAM` - about `$0.1632/hr` and `$3.92/day`
- `L` - `g4dn.xlarge` - faster GPU-backed option when lower latency matters more than cost - `4 vCPU`, `16 GiB RAM`, `1x T4 GPU` - about `$0.5260/hr` and `$12.62/day`

Guidance:

- Pick `M` / `m7g.xlarge` by default.
- Use `S` / `m7g.large` only for a personal smoke test or very light usage.
- Use `L` / `g4dn.xlarge` only if you are intentionally paying for GPU inference.
- Add at least `40-60 GiB` of gp3 EBS on top of the compute cost.
