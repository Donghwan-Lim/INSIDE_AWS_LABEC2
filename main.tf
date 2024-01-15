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
      version = "5.10.0"
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
    Environment = "INSIDE__AWS_NETWORKS"
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
/* key pair managed by AWS Console
resource "tls_private_key" "ssh-priv-key" {
  algorithm = "ED25519"
}

### Resource to create a key pair
resource "aws_key_pair" "ssh-key-pair" {
  public_key = tls_private_key.ssh-priv-key.public_key_openssh
  key_name   = "INSIDE_AWS_KEY_PAIR"
}
*/
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
    values = ["x86_64"]
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

data "aws_ami" "recent_Ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
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

// Terraform Enterprise FDO Migration Test
// Terraform Enterprise EC2
resource "aws_instance" "Terraform_Enterprise_Donghwan" {
  ami                         = data.aws_ami.recent_amazon_linux.id
  instance_type               = "m5.large"
  subnet_id                   = data.terraform_remote_state.network.outputs.vpc01_public_subnet_01_id
  associate_public_ip_address = true

  key_name               = "INSIDE_EC2_KEYPAIR"
  vpc_security_group_ids = ["${data.terraform_remote_state.security.outputs.vpc1-public-vm-sg-id}","${data.terraform_remote_state.security.outputs.vpc1_terraform_sg-id}"]

  root_block_device {
    delete_on_termination = true
    encrypted             = false
    volume_type           = "gp3"
    volume_size           = 100
  }

  tags = (merge(local.common-tags, tomap({
    Name     = "Terraform_Enterprise_Donghwan"
    resource = "aws_ec2_instance"
  })))
}
// EIP For Terraform Enterprise
resource "aws_eip" "Terraform_Tenterprise_EIP" {
  domain = "vpc"
  instance = aws_instance.Terraform_Enterprise_Donghwan.id
}

//Route53 Records Deploy
resource "aws_route53_record" "" {
  zone_id = "Z05152881DEVAJ0LCCX8I"
  name    = "terraform"
  type    = "A"
  ttl     = 300
  records = [aws_eip.Terraform_Tenterprise_EIP.address]
}

//Terraform Enterprise LB & Target Group



/*
resource "aws_instance" "Ansible_Server" {
  ami                         = data.aws_ami.recent_Ubuntu.id
  instance_type               = "t2.micro"
  subnet_id                   = data.terraform_remote_state.network.outputs.vpc01_public_subnet_01_id
  associate_public_ip_address = true

  key_name               = "INSIDE_EC2_KEYPAIR"
  vpc_security_group_ids = ["${data.terraform_remote_state.security.outputs.vpc1-public-vm-sg-id}"]

  root_block_device {
    delete_on_termination = true
    encrypted             = false
    volume_type           = "gp3"
    volume_size           = 50
  }

  tags = (merge(local.common-tags, tomap({
    Name     = "Ansible_Server"
    resource = "aws_ec2_instance"
  })))
}

resource "aws_instance" "Ansible_Node_01" {
  ami                         = data.aws_ami.recent_Ubuntu.id
  instance_type               = "t2.micro"
  subnet_id                   = data.terraform_remote_state.network.outputs.vpc02_private_subnet_01_id
  associate_public_ip_address = false

  key_name               = "INSIDE_EC2_KEYPAIR"
  vpc_security_group_ids = ["${data.terraform_remote_state.security.outputs.vpc2-private-vm-sg-id}"]

  root_block_device {
    delete_on_termination = true
    encrypted             = false
    volume_type           = "gp3"
    volume_size           = 50
  }

  tags = (merge(local.common-tags, tomap({
    Name     = "Ansible_Node_01"
    resource = "aws_ec2_instance"
  })))
}
/*
resource "aws_instance" "Ansible_Node_02" {
  ami                         = data.aws_ami.recent_Ubuntu.id
  instance_type               = "t2.micro"
  subnet_id                   = data.terraform_remote_state.network.outputs.vpc01_public_subnet_01_id
  associate_public_ip_address = true

  key_name               = "INSIDE_EC2_KEYPAIR"
  vpc_security_group_ids = ["${data.terraform_remote_state.security.outputs.vpc1-public-vm-sg-id}"]

  root_block_device {
    delete_on_termination = true
    encrypted             = false
    volume_type           = "gp3"
    volume_size           = 50
  }

  tags = (merge(local.common-tags, tomap({
    Name     = "Ansible_Node_02"
    resource = "aws_ec2_instance"
  })))
}

resource "aws_instance" "Ansible_Node_03" {
  ami                         = data.aws_ami.recent_Ubuntu.id
  instance_type               = "t2.micro"
  subnet_id                   = data.terraform_remote_state.network.outputs.vpc01_public_subnet_01_id
  associate_public_ip_address = true

  key_name               = "INSIDE_EC2_KEYPAIR"
  vpc_security_group_ids = ["${data.terraform_remote_state.security.outputs.vpc1-public-vm-sg-id}"]


  root_block_device {
    delete_on_termination = true
    encrypted             = false
    volume_type           = "gp3"
    volume_size           = 50
  }

  tags = (merge(local.common-tags, tomap({
    Name     = "Ansible_Node_03"
    resource = "aws_ec2_instance"
  })))
}*/

# VM Create Terraform Enter Prise VM
/*
resource "aws_instance" "TerraformEnterprise" {
  ami           = data.aws_ami.recent_amazon_linux.id
  instance_type = "t3.medium"
  subnet_id     = data.terraform_remote_state.network.outputs.vpc01_public_subnet_01_id
  associate_public_ip_address = true

  key_name        = "INSIDE_EC2_KEYPAIR"
  vpc_security_group_ids = ["${data.terraform_remote_state.security.outputs.vpc1-public-vm-sg-id}"]

  root_block_device {
    delete_on_termination = true
    encrypted             = false
    volume_type           = "gp3"
    volume_size           = 50
  }

  tags = (merge(local.common-tags, tomap({
    Name     = "Terraform_Enterprise"
    resource = "aws_ec2_instance"
  })))
}
*/

/*
resource "aws_instance" "public_vm_02" {
  ami           = data.aws_ami.recent_Ubuntu.id
  instance_type = var.instnace_type
  subnet_id     = data.terraform_remote_state.network.outputs.vpc02_public_subnet_01_id
  associate_public_ip_address = true

  key_name        = "INSIDE_EC2_KEYPAIR"
  vpc_security_group_ids = ["${data.terraform_remote_state.security.outputs.vpc2-public-vm-sg-id}"]

  root_block_device {
    delete_on_termination = true
    encrypted             = false
    volume_type           = "gp3"
    volume_size           = 50
  }

  tags = (merge(local.common-tags, tomap({
    Name     = "public_vm_02_vpc2"
    resource = "aws_ec2_instance"
  })))
}*/