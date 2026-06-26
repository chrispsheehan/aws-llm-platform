# Repo Instructions

These instructions apply to the entire repository.
Keep note in this `AGENTS.md` of any new user instruction that makes a material difference to agent behavior.
Keep `README.md` files up to date with any material changes.
Load the relevant `README.md` in a directory before making code changes there to gather context.

Current repo-specific guidance to preserve unless the user changes it:
- The default local model is `qwen2.5-coder:3b`.
- The top-level `README.md` includes EC2 recommendations for self-hosting this stack with T-shirt sizing:
  `S` = `m7g.large`, `M` = `m7g.xlarge`, `L` = `g4dn.xlarge`.
- The repo now includes a dev-only Terragrunt scaffold guided by `aws-terragrunt-starter`:
  single `EC2` Docker host, `ECR`, GitHub OIDC, and infra-only deploy / destroy flows.
