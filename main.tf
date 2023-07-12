### Terraform Cloud Info as Backend Storage and execution ###
terraform {
  cloud {
    hostname     = "app.terraform.io"
    organization = "Insideinfo"
    workspaces {
      name = "INSIDE_AWS_LABEC2"
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.7.0"
    }
  }
}

### AWS Provider Info ###
provider "aws" {
  region = var.region
}

locals {
  common-tags = {
    author      = "DonghwanLim"
    system      = "LAB"
    Environment = "INSIDE__AWS_NETWORK"
  }
}

### AWS NETWORK Config GET ###
data "terraform_remote_state" "network" {
  backend = "remote"
  config = {
    organization = "Insideinfo"
    workspaces = {
      name = "INSIDE_AWS_LABNET"
    }
  }
}

data "terraform_remote_state" "security" {
  backend = "remote"
  config = {
    organization = "Insideinfo"
    workspaces = {
      name = "INSIDE_AWS_LABSGs"
    }
  }
}

### Key Pair ###
### Resource to create a SSH private key
resource "tls_private_key" "ssh-priv-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

### Resource to create a key pair
resource "aws_key_pair" "ssh-key-pair" {
  public_key = tls_private_key.ssh-priv-key.public_key_openssh
  key_name   = "INSIDE_AWS_KEY_PAIR"
}

### Download key pair to local file
/* After Local Terraform cli apply to download PEM File To local File System, Comment out this resource.
resource "local_file" "local_key_pair" {
    filename = "${aws_key_pair.ssh-key-pair.key_name}.pem"
    file_permission = "0400"
    content = tls_private_key.ssh-priv-key.private_key_pem
}
*/

### EC2 Instance ###
### AMI Image Select ###
data "aws_ami" "recent_amazon_linux" {
  most_recent = true
  owners      = ["137112412989"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "public_vm_01" {
  ami           = data.aws_ami.recent_amazon_linux.id
  instance_type = var.instnace_type
  subnet_id     = data.terraform_remote_state.network.outputs.vpc01_public_subnet_01_id

  key_name        = aws_key_pair.ssh-key-pair.key_name
  security_groups = ["${aws_security_group.public_vm_sg.id}"]

  root_block_device {
    delete_on_termination = true
    encrypted             = false
    volume_type           = "gp3"
    volume_size           = 50
  }

  tags = (merge(local.common-tags, tomap({
    Name     = "public_vm_01"
    resource = "aws_ec2_instance"
  })))
}

resource "aws_security_group" "public_vm_sg" {
  name        = "public_vm_sg"
  description = "INSIDE_AWS_Public_VM_Security_GROUP"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc01_id

  tags = local.common-tags
}