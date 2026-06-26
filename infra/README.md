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
export AWS_PROFILE=default
export AWS_REGION=eu-west-2

just tg dev aws/oidc apply
```

This minimal dev scaffold expects the target AWS account and region to still
have a default VPC with at least one default subnet. The `ec2_host` module
launches into that default network instead of creating a dedicated VPC.

Then set these GitHub Actions repository variables:

```text
AWS_ACCOUNT_ID=<your aws account id>
AWS_REGION=eu-west-2
PROJECT_NAME=aws-llm-platform
```

## Defaults

- Default region: `eu-west-2`
- Default dev host size: `t3.xlarge`
- Default root volume size: `80 GiB`
- Default model: `qwen2.5-coder:3b`

The `EC2` default is `x86_64` on purpose so infra apply can mirror the upstream
container images into `ECR` without a separate multi-arch build pipeline.
