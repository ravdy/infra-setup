data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    # fixing name to avoid undesirable moving target
    values = var.ec2_ami_filter

  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_security_group" "default" {
  name = "default"
  vpc_id = module.env-segment.vpc_id
}

resource "aws_instance" "controller" {
  ami = data.aws_ami.ubuntu.id
  iam_instance_profile = aws_iam_role.ssm_managed.name
  instance_type = "t3a.large"
  subnet_id = module.env-segment.vpc_private_subnets_ids[0]
  key_name = "edbence-${var.environment}"
  associate_public_ip_address = false
  #  security_groups = [ data.aws_security_group.default.id]
  vpc_security_group_ids = [data.aws_security_group.default.id]
  tags = {
    Name = "controller-${var.segment}"
    Purpose = "GitLab agent and segment controller"
    Logging = "by_DD"
  }
  root_block_device {
    volume_size = 100
    volume_type = "gp3"
  }
}

resource "aws_route53_record" "controller" {
  name    = "controller-${var.segment}"
  type    = "A"
  zone_id = module.env-segment.internal_dns_id
  ttl = 300
  records = [ aws_instance.controller.private_ip ]
}

resource "aws_iam_role" "ssm_managed" {
  name = "ssm-managed-instance-${var.environment}-${var.segment}"
  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = { Service = "ec2.amazonaws.com" }
        },
      ]
      Version = "2012-10-17"
    }
  )
}

resource "aws_iam_instance_profile" "ssm_managed" {
  name = aws_iam_role.ssm_managed.name
  role = aws_iam_role.ssm_managed.name
}

resource "aws_iam_role_policy_attachment" "ssm_managed" {
  role = aws_iam_role.ssm_managed.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
