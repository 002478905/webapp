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
  default = "subnet-04627e74a7ab23048"
}
variable "demo_account_id" {
  type        = string
  description = "195275650791"
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

  # Step 1: Copy the application zip file to the instance
  provisioner "file" {
    source      = var.artifact_path
    destination = "/home/ubuntu/application.zip"
  }

  # Step 2: Install necessary software and configure the instance
  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -",
      "sudo apt-get install -y nodejs unzip",

      # Download and install Amazon CloudWatch Agent
      "wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb",
      "sudo dpkg -i amazon-cloudwatch-agent.deb",

      # Create user `csye6225` with no login
      "sudo useradd -M -s /usr/sbin/nologin csye6225 || true",

      # Set up application directories and permissions
      "sudo mkdir -p /home/csye6225/webapp",
      "sudo unzip /home/ubuntu/application.zip -d /home/csye6225/webapp",
      "sudo chown -R csye6225:csye6225 /home/csye6225/webapp",

      # Move service file and enable it
      "sudo mv /home/csye6225/webapp/app.service /etc/systemd/system/",
      "sudo systemctl daemon-reload",

      "sudo systemctl enable app"
    ]
  }

  # Upload CloudWatch configuration file
  provisioner "file" {
    source      = "cloudwatch-config.json"
    destination = "/home/ubuntu/amazon-cloudwatch-agent.json"
  }

  # Configure and start CloudWatch Agent
  provisioner "shell" {
    inline = [
      "sudo mv /home/ubuntu/amazon-cloudwatch-agent.json /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json",
      "aws logs create-log-group --log-group-name '/my-app/logs' || true",
      "sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s",
      "sudo systemctl start amazon-cloudwatch-agent",
      "sudo systemctl status amazon-cloudwatch-agent"
    ]
  }

  # Ensure application service starts as well
  provisioner "shell" {
    inline = [

      "sudo systemctl daemon-reload",
      "sudo systemctl restart app.service",
      "sudo systemctl enable app.service",
      "sudo systemctl start app.service"
    ]
  }
}
build {
  sources = ["source.amazon-ebs.my-ami"]

  # Step 1: Copy application zip file and configure instance
  provisioner "file" {
    source      = var.artifact_path
    destination = "/home/ubuntu/application.zip"
  }

  # Step 2: Install necessary software and configure instance
  provisioner "shell" {
    inline = [
      # Your existing setup commands...
      # Update package lists
      "sudo apt-get update",

      # Install Node.js (version 16.x)
      "curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -",
      "sudo apt-get install -y nodejs",

      # Install unzip utility
      "sudo apt-get install -y unzip",

      # Install Amazon CloudWatch Agent
      "wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb",
      "sudo dpkg -i amazon-cloudwatch-agent.deb",

      # Create a new system user `csye6225` with no login access
      "sudo useradd -M -s /usr/sbin/nologin csye6225 || true",

      # Create directories for the web application
      "sudo mkdir -p /home/csye6225/webapp",

      # Unzip the application artifact (application.zip) into the webapp directory
      "sudo unzip /home/ubuntu/application.zip -d /home/csye6225/webapp",

      # Set ownership of the webapp directory to `csye6225` user
      "sudo chown -R csye6225:csye6225 /home/csye6225/webapp",

      # Move the service file into systemd directory and reload systemd daemon
      "sudo mv /home/csye6225/webapp/app.service /etc/systemd/system/",
      "sudo systemctl daemon-reload",

      # Enable and start the `app` service (your web application)
      "sudo systemctl enable app.service",
      "sudo systemctl start app.service"
    ]
  }

  # Step 3: Post-process to share AMI with demo account
  post-processors {
    type = "shell-local"
    inline = [
      "aws ec2 modify-image-attribute --image-id {{ .ArtifactId }} --launch-permission 'Add=[{UserId=${var.demo_account_id}}]'"
    ]
  }
}