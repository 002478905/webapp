# Packer configuration for building the AMI
variable "artifact_path" {
  type    = string
  default = "application.zip"
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
  default = "subnet-04627e74a7ab23048"
}

packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.1"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "my-ami" {
  region          = var.aws_region
  ami_name        = "csye6225-coursework-${formatdate("YYYY_MM_DD-hh-mm-ss", timestamp())}"
  ami_description = "Custom AMI for CSYE 6225 Web Application"

  ami_regions = ["us-east-1"]

  aws_polling {
    delay_seconds = 120
    max_attempts  = 50
  }

  instance_type = "t2.micro"
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
  sources = ["source.amazon-ebs.my-ami"]

  # Copy the application zip file to the instance
  provisioner "file" {
    source      = var.artifact_path
    destination = "/home/ubuntu/application.zip"
  }

  # Copy the CloudWatch configuration file to the instance
  provisioner "file" {
    source      = "cloudwatch-config.json"
    destination = "/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json"
  }

  # Install necessary software and configure the instance
  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y nodejs unzip amazon-cloudwatch-agent",
      "curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -",

      # Create a non-login user for the application
      "sudo useradd -M -s /usr/sbin/nologin csye6225 || true",

      # Create application directory, unzip, and set ownership
      "sudo mkdir -p /home/csye6225/webapp",
      "sudo unzip /home/ubuntu/application.zip -d /home/csye6225/webapp",
      "sudo chown -R csye6225:csye6225 /home/csye6225/webapp",

      # Move the app.service file and enable it
      "sudo mv /home/csye6225/webapp/app.service /etc/systemd/system/",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable app"
    ]
  }

  # Configure and start CloudWatch Agent
  provisioner "shell" {
    inline = [
      "echo Starting CloudWatch configuration",

      # Start the CloudWatch Agent
      "sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s",
      "sleep 5",
      "sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a status"
    ]
  }

  # Ensure the application service is running
  provisioner "shell" {
    inline = [
      "sudo systemctl daemon-reload",
      "sudo systemctl enable app.service",
      "sudo systemctl start app.service"
    ]
  }
}
