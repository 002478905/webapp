# Packer configuration to build a custom AMI for the web application
variable "artifact_path" {
  type    = string
  default = "application.zip"  # Path to the application artifact that needs to be copied to the instance
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "source_ami" {
  type    = string
  default = "ami-0866a3c8686eaeeba"  # Example Ubuntu 24.04 LTS AMI, modify as needed
}

variable "ssh_username" {
  type    = string
  default = "ubuntu"
}

variable "subnet_id" {
  type    = string
  default = "subnet-0eb60cf3e6d3319d4"  # Example subnet, modify according to your setup
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

  instance_type   = "t2.small"
  source_ami      = var.source_ami
  ssh_username    = var.ssh_username
  subnet_id       = var.subnet_id

  ami_regions = [
    "us-east-1",
  ]

  aws_polling {
    delay_seconds = 120
    max_attempts  = 50
  }

  # Root volume settings
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
    source      = var.artifact_path
    destination = "/home/ubuntu/application.zip"
  }

  # Step 2: Install necessary software and configure the instance
  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y unzip",

      # Step 3: Create a directory for the application
      "sudo mkdir -p /home/csye6225/webapp",
      
      # Step 4: Unzip the application artifact into the application directory
      "sudo unzip /home/ubuntu/application.zip -d /home/csye6225/webapp",
      
      # Step 5: Set the ownership of the webapp folder to a system user
      "sudo chown -R csye6225:csye6225 /home/csye6225/webapp",

      # Step 6: Move the app service file (if it exists) to systemd
      "if [ -f /home/csye6225/webapp/app.service ]; then sudo mv /home/csye6225/webapp/app.service /etc/systemd/system/; fi",

      # Step 7: Reload systemd daemon and enable the service
      "sudo systemctl daemon-reload",
      "sudo systemctl enable app"
    ]
  }

  # Step 8: Start the service as part of the image creation
  provisioner "shell" {
    inline = [
      "sudo systemctl daemon-reload",
      "sudo systemctl start app.service"
    ]
  }
}
