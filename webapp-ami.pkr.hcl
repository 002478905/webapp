packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.1"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "artifact" {
  type    = string
  default = "app.zip"
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "csye6225-coursework-${formatdate("YYYY-MM-DD-hh-mm-ss", timestamp())}"
  instance_type = "t2.micro"
  region        = var.aws_region
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-jammy-24.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["557690620867"]
  }
  ssh_username = "ubuntu"
}

build {
  name = "csye6225-coursework"
  sources = ["source.amazon-ebs.ubuntu"]

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get upgrade -y",
      "sudo apt-get install -y nodejs npm mysql-server"
    ]
  }

  # Create a non-login user and group
  provisioner "shell" {
    inline = [
      "sudo groupadd csye6225",
      "sudo useradd -g csye6225 -s /usr/sbin/nologin csye6225",
      "sudo mkdir -p /home/csye6225/webapp",
      "sudo chown -R csye6225:csye6225 /home/csye6225/webapp"
    ]
  }

  # Copy application artifact
  provisioner "file" {
    source = var.artifact
    destination = "/home/csye6225/webapp/app.zip"
  }

  # Unzip application artifact, set permissions, and configure service
  provisioner "shell" {
    inline = [
      "sudo unzip /home/csye6225/webapp/app.zip -d /home/csye6225/webapp/",
      "sudo chown -R csye6225:csye6225 /home/csye6225/webapp",
      "sudo cp /home/csye6225/webapp/myapp.service /etc/systemd/system/",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable myapp.service"
    ]
  }
}
