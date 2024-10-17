variable "artifact_path" {
  type    = string
  default = "application.zip"
}

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

variable "source_ami" {
  type    = string
  default = "ami-0866a3c8686eaeeba" # Ubuntu 24.04 LTS
}

variable "ssh_username" {
  type    = string
  default = "ubuntu"
}

variable "subnet_id" {
  type    = string
  default = "subnet-0eb60cf3e6d3319d4"
}

source "amazon-ebs" "my-ami" {
  region          = var.aws_region
  ami_name        = "csye6225-coursework-${formatdate("YYYY_MM_DD-hh-mm-ss", timestamp())}"
  ami_description = "Custom AMI for CSYE 6225 Web Application"

  ami_regions = [
    "us-east-1",
  ]

  aws_polling {
    delay_seconds = 120
    max_attempts  = 50
  }

  instance_type = "t2.small"
  source_ami    = var.source_ami
  ssh_username  = var.ssh_username
  subnet_id     = var.subnet_id

  launch_block_device_mappings {
    delete_on_termination = true
    device_name           = "/dev/sda1"
    volume_size           = 25
    volume_type           = "gp2"
  }
}

build {
  sources = [
    "source.amazon-ebs.my-ami",
  ]

  # Step 1: Copy the application zip file to the instance
  provisioner "file" {
    source      = var.artifact_path # Ensure the application zip is built and available
    destination = "/home/ubuntu/application.zip"
  }

  # Step 2: Install necessary software (PostgreSQL) and configure the instance
  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y postgresql postgresql-contrib unzip",

      # Step 3: Create user csye6225 with no login
      "sudo useradd -M -s /usr/sbin/nologin csye6225",

      # Step 4: Set up PostgreSQL (this can be adjusted depending on your needs)
      "sudo -u postgres psql -c \"CREATE ROLE csye6225 WITH LOGIN PASSWORD 'password';\"",
      "sudo -u postgres psql -c \"CREATE DATABASE myappdb WITH OWNER csye6225;\"",

      # Step 5: Create directories and unzip the application
      "sudo mkdir -p /home/csye6225/webapp",
      "sudo unzip /home/ubuntu/ .zip -d /home/csye6225/webapp",

      # Step 6: Set ownership to the user and group csye6225
      "sudo chown -R csye6225:csye6225 /home/csye6225/webapp",
      "sudo mv /home/csye6225/app/app.service /etc/systemd/system/",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable app"
    ]
  }

  # Step 7: Add systemd service to run the web application
  // provisioner "file" {
  //   source      = "./app.service" # Make sure your app.service file is available
  //   destination = "/etc/systemd/system/app.service"
  // }

  # Step 8: Reload systemd, enable, and start the service
  provisioner "shell" {
    inline = [
      "sudo systemctl daemon-reload",
      "sudo systemctl enable app.service",
      "sudo systemctl start app.service"
    ]
  }
}