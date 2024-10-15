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
  ami_name      = "my-nodejs-postgres-app-{{timestamp}}"
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
  sources = ["source.amazon-ebs.ubuntu"]

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y nodejs npm postgresql postgresql-contrib",
      "sudo systemctl enable postgresql",
      "sudo systemctl start postgresql",
      "sudo -u postgres psql -c \"CREATE USER postgres WITH PASSWORD 'root';\"",
      "sudo -u postgres psql -c \"CREATE DATABASE webapp OWNER postgres;\"",
      "sudo npm install -g pm2"
    ]
  }

  # Instead of using a file provisioner for .env, we create it using shell commands
  provisioner "shell" {
    inline = [
      "echo 'DB_USER=${DB_USER}' >> /home/ubuntu/app/.env",
      "echo 'DB_PASSWORD=${DB_PASSWORD}' >> /home/ubuntu/app/.env",
      "echo 'DB_NAME=${DB_NAME}' >> /home/ubuntu/app/.env",
      "echo 'DB_HOST=${DB_HOST}' >> /home/ubuntu/app/.env",
      "echo 'DB_PORT=${DB_PORT}' >> /home/ubuntu/app/.env"
    ]
    environment_vars = [
      "DB_USER=${DB_USER}",
      "DB_PASSWORD=${DB_PASSWORD}",
      "DB_NAME=${DB_NAME}",
      "DB_HOST=${DB_HOST}",
      "DB_PORT=${DB_PORT}"
    ]
  }

  provisioner "file" {
    source      = "./"
    destination = "/home/ubuntu/app"
  }

  provisioner "shell" {
    inline = [
      "cd /home/ubuntu/app",
      "npm install",
      "sudo pm2 startup systemd",
      "pm2 start index.js",
      "pm2 save"
    ]
  }
}
