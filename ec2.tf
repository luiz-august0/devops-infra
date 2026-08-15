## Busca a AMI mais recente do Ubuntu
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

## Cria o par de chaves
resource "aws_key_pair" "devops_infra_key_pair" {
  key_name   = "devops_infra_key_pair"
  public_key = var.ssh_public_key
}

## Busca a VPC padrão
data "aws_vpc" "default" {
  default = true
}

## Cria o security group
resource "aws_security_group" "devops_infra_ec2_security_group" {
  name   = "devops_infra_ec2_security_group"
  vpc_id = data.aws_vpc.default.id
}

## Regras de entrada para SSH
resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.devops_infra_ec2_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

## Regras de entrada para HTTP
resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.devops_infra_ec2_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

## Regras de entrada para HTTPS
resource "aws_vpc_security_group_ingress_rule" "allow_https" {
  security_group_id = aws_security_group.devops_infra_ec2_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

## Regras de saída permitindo tudo
resource "aws_vpc_security_group_egress_rule" "allow_all" {
  security_group_id = aws_security_group.devops_infra_ec2_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

## Role para o EC2 acessar o ECR
resource "aws_iam_role" "ec2_ecr_access_iam_role" {
  name = "ec2_ecr_access_iam_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    tag-key = "ec2-ecr-access"
  }
}

## Policy para o EC2 acessar o ECR
resource "aws_iam_role_policy" "ec2_ecr_access_iam_role_policy" {
  name = "ec2_ecr_access_iam_role_policy"
  role = aws_iam_role.ec2_ecr_access_iam_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:GetLifecyclePolicy",
          "ecr:GetLifecyclePolicyPreview",
          "ecr:ListTagsForResource",
          "ecr:DescribeImageScanFindings"
        ]
        Resource = "*"
      }
    ]
  })
}

## Instance profile para o EC2
resource "aws_iam_instance_profile" "ec2_ecr_access_iam_instance_profile" {
  name = "ec2_ecr_access_iam_instance_profile"
  role = aws_iam_role.ec2_ecr_access_iam_role.name
}

## Cria a instância EC2
resource "aws_instance" "devops_infra_ec2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.devops_infra_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.devops_infra_ec2_security_group.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_ecr_access_iam_instance_profile.name
  user_data              = file("user_data.sh")
}
