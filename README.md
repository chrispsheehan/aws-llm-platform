# Local Open-Source LLM Chat

This repo includes a Docker Compose stack for a fully self-hosted chat UI using:

- `Open WebUI` for the chat interface
- `Ollama` for local model serving
- `qwen2.5-coder:3b` as the default model configured in Compose for a better small local coding model

## Run Locally

Start the local stack:

```bash
just start
```

Then open `http://localhost:3000`.

What `just start` does:

- pulls the Compose images
- starts `open-webui` and `ollama`
- pulls the default Ollama model configured by `OLLAMA_DEFAULT_MODEL`
- prints the installed Ollama models
- opens `http://localhost:3000` on macOS

To stop the local stack:

```bash
docker compose down
```

Notes:

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
just setup
just apply
just destroy
just ssh
```

`just setup` applies the one-time GitHub OIDC role in `infra/live/dev/aws/oidc`.
`just apply` deploys the dev Terragrunt stacks after OIDC bootstrap.
Bootstrap and workflow details live in [infra/README.md](infra/README.md).
The dev `EC2` ingress is IP-restricted by default. When `web_ingress_cidrs` is
omitted, Terraform defaults it to `["192.168.1.1"]` and normalizes plain IPv4
addresses to `/32`.
If you set `web_ingress_cidrs` explicitly, you can pass either a plain IPv4
address or a CIDR block; plain IPv4 addresses are normalized to `/32` by the
module.
For plain SSH access, the dev Terragrunt config defaults `ssh_public_key` from
`~/.ssh/id_ed25519.pub` when that file exists. `just setup`, `just apply`, and
`just plan` will inject that file automatically as `TF_VAR_ssh_public_key`
unless it is already set. Set `SSH_PUBLIC_KEY_PATH` if your public key lives
somewhere else. CI applies should set `TF_VAR_ssh_public_key` as a GitHub
Actions secret. `just ssh` uses `~/.ssh/id_ed25519` by default and fails if
that private key file does not exist.

## EC2 sizing

For a self-hosted coding assistant with `open-webui`, `ollama`, and `qwen2.5-coder:3b`, these are the practical EC2 starting points in `eu-west-2`:

- `S` - `m7g.large` - cheapest possible experiment - `2 vCPU`, `8 GiB RAM` - about `$0.0944/hr` and `$2.27/day`
- `M` - `m7g.xlarge` - recommended minimum for realistic Codex-like CLI experimentation - `4 vCPU`, `16 GiB RAM` - about `$0.1887/hr` and `$4.53/day`
- `L` - `g4dn.xlarge` - faster GPU-backed option when lower latency matters more than cost - `4 vCPU`, `16 GiB RAM`, `1x T4 GPU` - about `$0.6150/hr` and `$14.76/day`

Guidance:

- Pick `M` / `m7g.xlarge` by default.
- Use `S` / `m7g.large` only for a personal smoke test or very light usage.
- Use `L` / `g4dn.xlarge` only if you are intentionally paying for GPU inference.
- Add at least `40-60 GiB` of gp3 EBS on top of the compute cost.
