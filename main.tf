locals {
  account_id = ""
  region     = "eu-central-1"
}


terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "< 4"
    }
  }
}

provider "aws" {
  profile             = "default"
  region              = local.region
  allowed_account_ids = [local.account_id]
}

resource "aws_key_pair" "key" {
  key_name   = "main_key"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_instance" "neo4j_instance" {
  ami                         = "ami-08b6922679a8f4279"
  instance_type               = "m3.medium"
  associate_public_ip_address = true
  key_name                    = aws_key_pair.key.key_name
  security_groups             = [aws_security_group.allow_neo4j.name, aws_security_group.instance_ssh_access.name]
}

resource "aws_security_group" "allow_neo4j" {
  name        = "neo4j-security-group"
  description = "Allow NEO4J inbound traffic"
  ingress {
    description = "Neo4J secure"
    from_port   = 7473
    to_port     = 7473
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Neo4J non secure"
    from_port   = 7474
    to_port     = 7474
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Neo4J ws"
    from_port   = 7687
    to_port     = 7687
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "instance_ssh_access" {
  description = "Allow SSH to instance with ssm agent"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    self        = true
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

