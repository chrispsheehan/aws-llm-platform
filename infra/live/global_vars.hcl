locals {
  aws_region = "eu-west-2"
  vpc_name   = "vpc"
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
  vpc_name             = local.vpc_name
  allowed_role_actions = local.allowed_role_actions
}
