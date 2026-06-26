resource "aws_key_pair" "this" {
  count = local.ssh_enabled ? 1 : 0

  key_name   = "${local.name_prefix}-ssh"
  public_key = trimspace(var.ssh_public_key)
}

resource "aws_iam_role" "instance" {
  name               = "${local.name_prefix}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy" "ecr_pull" {
  name   = "${local.name_prefix}-ecr-pull"
  role   = aws_iam_role.instance.id
  policy = data.aws_iam_policy_document.ecr_pull.json
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "this" {
  name = "${local.name_prefix}-ec2-profile"
  role = aws_iam_role.instance.name
}

resource "aws_security_group" "this" {
  name        = "${local.name_prefix}-web-sg"
  description = "Dev web access for ${local.name_prefix}"
  vpc_id      = data.aws_vpc.this.id

  ingress {
    description = "Open WebUI"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = local.effective_web_ingress_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "ssh" {
  count = local.ssh_enabled ? length(local.effective_web_ingress_cidrs) : 0

  type              = "ingress"
  description       = "SSH"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [local.effective_web_ingress_cidrs[count.index]]
  security_group_id = aws_security_group.this.id
}

resource "aws_instance" "this" {
  ami                         = data.aws_ssm_parameter.amazon_linux.value
  instance_type               = var.instance_type
  iam_instance_profile        = aws_iam_instance_profile.this.name
  associate_public_ip_address = true
  key_name                    = local.ssh_enabled ? aws_key_pair.this[0].key_name : null
  subnet_id                   = data.aws_subnets.public.ids[0]
  vpc_security_group_ids      = [aws_security_group.this.id]

  root_block_device {
    volume_size = var.root_volume_size_gb
    volume_type = "gp3"
  }

  user_data = local.user_data
}

resource "aws_eip" "this" {
  domain   = "vpc"
  instance = aws_instance.this.id
}
