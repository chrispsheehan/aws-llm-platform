# Infra Notes

This repo uses a reduced Terragrunt layout inspired by
`aws-terragrunt-starter`, but only for a single `dev` environment and a single
Docker host on `EC2`.

## Stacks

- `aws/oidc`: GitHub Actions deploy role for this repository
- `aws/ecr`: one stack that creates one private `ECR` repository and seeds both images under separate tags
- `aws/ec2_host`: one `EC2` instance with Docker, SSM, and a public web entry

## Deploy Model

- Infra deploy uses Terragrunt apply.
- The `ECR` module mirrors the upstream Docker images during infra apply, so
  the initial instance boot can pull from private `ECR` without a second
  deploy phase.
  The live stack passes both upstream image names and source tags explicitly,
  and stores them in one repository under separate target tags.
- Destroy removes `EC2` and `ECR` in reverse dependency order.
- The GitHub destroy workflow intentionally excludes `oidc` so it does not
  delete the role it is currently using.

## Bootstrap

Before GitHub Actions can deploy, create the `dev` OIDC role once from a local
shell that already has AWS credentials:

```bash
just setup
```

This minimal dev scaffold expects the target AWS account and region to already
contain a VPC with `Name` tag `vpc` and at least one public subnet with a
`Name` tag containing `public`. The `ec2_host` module looks up that VPC and
those public subnets instead of creating a dedicated network.

The default `web_ingress_cidrs` value is intentionally empty. When left empty,
the `ec2_host` module resolves the current public IP from
`https://checkip.amazonaws.com` and applies it as a `/32`.
If you want SSH access, the dev Terragrunt config defaults `ssh_public_key`
from `~/.ssh/id_ed25519.pub` when that file exists. `SSH_PUBLIC_KEY` still
overrides that default. In GitHub Actions, set `SSH_PUBLIC_KEY` as a
repository or environment secret. That causes the module to create an `EC2`
key pair, attach it to the instance, and open port `22` to the same
IP-restricted CIDRs.

Then set these GitHub Actions repository variables:

```text
AWS_ACCOUNT_ID=<your aws account id>
AWS_REGION=eu-west-2
PROJECT_NAME=aws-llm-platform
```

And set this GitHub Actions secret if you want SSH enabled from CI-managed
applies:

```text
SSH_PUBLIC_KEY=<contents of ~/.ssh/id_ed25519.pub>
```

## Defaults

- Default region: `eu-west-2`
- Default VPC name: `vpc`
- Default dev host size: `t3.xlarge`
- Default root volume size: `80 GiB`
- Default model: `qwen2.5-coder:3b`
- Default web ingress: current public IP detected at apply time from `https://checkip.amazonaws.com`
- Default SSH access: `~/.ssh/id_ed25519.pub` when present locally, otherwise disabled unless `SSH_PUBLIC_KEY` is set

The `EC2` default is `x86_64` on purpose so infra apply can mirror the upstream
container images into `ECR` without a separate multi-arch build pipeline.
