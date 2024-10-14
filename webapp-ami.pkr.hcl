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
    owners      = ["557690620867"] # Canonical
  }
  ssh_username = "ubuntu"
}

build {
  name = "csye6225-coursework"
  sources = [
    "source.amazon-ebs.ubuntu"
  ]

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get upgrade -y",
      "sudo apt-get install -y nodejs npm mysql-server",
      "sudo systemctl enable mysql",
      "sudo systemctl start mysql"
    ]
  }

  provisioner "file" {
    source      = "./"
    destination = "/home/ubuntu/webapp"
  }

  provisioner "shell" {
    inline = [
      "cd /home/ubuntu/webapp",
      "npm install",
      "sudo npm install -g pm2",
      "pm2 startup systemd",
      "sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u ubuntu --hp /home/ubuntu",
      "pm2 start app.js",
      "pm2 save"
    ]
  }
}