locals {
  aws_region = "eu-west-2"
  allowed_role_actions = [
    "ec2:*",
    "ecr:*",
    "iam:*",
    "s3:*",
    "ssm:*",
  ]
}

inputs = {
  aws_region           = local.aws_region
  allowed_role_actions = local.allowed_role_actions
}
