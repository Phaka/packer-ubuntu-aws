packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "prefix" {
  type    = string
  default = "phaka"
}

variable "source_ip" {
  type    = string
  default = "0.0.0.0/0"
}

variable "regions" {
  type    = list(string)
  default = [
    "us-east-1",
    "us-east-2",
    "us-west-1",
    "us-west-2",
  ]
}

variable "account_ids" {
  type    = list(string)
  default = []
}

variable "subnet_id" {
  type    = string
}

variable "vpc_id" {
  type    = string
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "ubuntu-xenial" {
  ami_name        = "${var.prefix}-base-xenial-16.04-amd64-${local.timestamp}"
  ami_description = "${var.prefix} base image of Ubuntu, 16.04 LTS, amd64 xenial image build on ${timestamp()}"
  associate_public_ip_address = true
  instance_type   = "m4.large"
  subnet_id       = var.subnet_id
  temporary_security_group_source_cidrs = [var.source_ip]
  tags = {
    BuildRegion = "{{ .BuildRegion }}"
    SourceAMI   = "{{ .SourceAMI }}"
  }
  vpc_id = var.vpc_id
  region = var.regions[0]
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-xenial-16.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username = "ubuntu"
  ami_regions = var.regions
  ami_users = var.account_ids
}

source "amazon-ebs" "ubuntu-focal" {
  ami_name        = "${var.prefix}-base-focal-20.04-amd64-${local.timestamp}"
  ami_description = "${var.prefix} base image of Ubuntu, 20.04 LTS, amd64 focal image build on ${timestamp()}"
  instance_type   = "m4.large"
  associate_public_ip_address = true
  temporary_security_group_source_cidrs = [var.source_ip]
  subnet_id       = var.subnet_id
  tags = {
    BuildRegion = "{{ .BuildRegion }}"
    SourceAMI   = "{{ .SourceAMI }}"
  }
  vpc_id = var.vpc_id
  region = var.regions[0]
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-focal-20.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username = "ubuntu"
  ami_regions = var.regions
  ami_users = var.account_ids
}

source "amazon-ebs" "ubuntu-trusty" {
  ami_name        = "${var.prefix}-base-trusty-14.04-amd64-${local.timestamp}"
  ami_description = "${var.prefix} base image of Ubuntu, 14.04 LTS, amd64 trusty image build on ${timestamp()}"
  instance_type   = "m4.large"
  associate_public_ip_address = true
  temporary_security_group_source_cidrs = [var.source_ip]
  subnet_id       = var.subnet_id
  tags = {
    BuildRegion = "{{ .BuildRegion }}"
    SourceAMI   = "{{ .SourceAMI }}"
  }
  vpc_id = var.vpc_id
  region = var.regions[0]
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-trusty-14.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username = "ubuntu"
  ami_regions = var.regions
  ami_users = var.account_ids
}

source "amazon-ebs" "ubuntu-bionic" {
  ami_name        = "phaka-base-bionic-18.04-amd64-${local.timestamp}"
  ami_description = "phaka base image of Ubuntu, 16.04 LTS, amd64 bionic image build on ${timestamp()}"
  instance_type   = "m4.large"
  associate_public_ip_address = true
  temporary_security_group_source_cidrs = [var.source_ip]
  subnet_id       = var.subnet_id
  tags = {
    BuildRegion = "{{ .BuildRegion }}"
    SourceAMI   = "{{ .SourceAMI }}"
  }
  vpc_id = var.vpc_id
  region = var.regions[0]
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-bionic-18.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username = "ubuntu"
  ami_regions = var.regions
  ami_users = var.account_ids
}

build {
  name = "phaka-base"
  sources = [
    "source.amazon-ebs.ubuntu-trusty", // 14.04 LTS
    "source.amazon-ebs.ubuntu-xenial", // 16.04 LTS
    "source.amazon-ebs.ubuntu-bionic", // 18.04 LTS
    "source.amazon-ebs.ubuntu-focal",  // 20.04 LTS
  ]
  provisioner "shell" {
    inline = [
      "echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections",
      "sudo add-apt-repository main",
      "sudo add-apt-repository universe",
      "sudo add-apt-repository restricted",
      "sudo add-apt-repository multiverse",
      "sudo apt-get -y update",
      "sudo apt-get -y upgrade",
    ]
  }
  // Install Endpoint Protection
  // Install Vulnerability Management Agent
}
