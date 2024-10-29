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
  # default = "subnet-0eb60cf3e6d3319d4"
  #  default ="subnet-003d768407efe7781"
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
  sources = [
    "source.amazon-ebs.my-ami",
  ]

  # Step 1: Copy the application zip file to the instance
  provisioner "file" {
    source      = var.artifact_path
    destination = "/home/ubuntu/application.zip"
  }

  # Step 2: Install necessary software (Node.js) and configure the instance
  provisioner "shell" {
    inline = [
      "sudo apt-get update",

      # Commented out PostgreSQL installation
      # "sudo apt-get install -y postgresql postgresql-contrib unzip",

      # Install Node.js
      "curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -",
      "sudo apt-get install -y nodejs unzip",

      # Download and install Amazon CloudWatch Agent
      "wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb",
      "sudo dpkg -i amazon-cloudwatch-agent.deb",

      # Step 3: Create user `csye6225` with no login
      "sudo useradd -M -s /usr/sbin/nologin csye6225 || true", # Ignore error if the user already exists

      # Commented out PostgreSQL role and database creation
      # "sudo -u postgres psql -c \"CREATE ROLE csye6225 WITH LOGIN PASSWORD 'password';\"",
      # "sudo -u postgres psql -c \"CREATE DATABASE myappdb WITH OWNER csye6225;\"",

      # Step 4: Create directories and unzip the application
      "sudo mkdir -p /home/csye6225/webapp",
      "sudo unzip /home/ubuntu/application.zip -d /home/csye6225/webapp", # Corrected path

      # Step 5: Set ownership to the user and group `csye6225`
      "sudo chown -R csye6225:csye6225 /home/csye6225/webapp",

      # Step 6: Ensure the app.service file exists before moving
      "sudo mv /home/csye6225/webapp/app.service /etc/systemd/system/; ",

      # Reload systemd daemon and enable the service
      "sudo systemctl daemon-reload",
      "sudo systemctl enable app"
    ]
  }

  # Step 3: Upload CloudWatch configuration file to a temporary location
  provisioner "file" {
    source      = "cloudwatch-config.json" # Make sure this file exists locally
    destination = "/home/ubuntu/amazon-cloudwatch-agent.json"
  }

  # Step 4: Move CloudWatch configuration to the correct location with sudo and create the log group
  provisioner "shell" {
    inline = [
      "aws iam attach-user-policy --user-name cyse6225-packer-user --policy-arn arn:aws:iam::<account-id>:policy/ec2_instance_profile || true",

      # Move the config file to the correct location
      "sudo mv /home/ubuntu/amazon-cloudwatch-agent.json /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json",
      "sleep 5",
      # Create the CloudWatch log group if it doesn't exist
      "aws logs create-log-group --log-group-name '/my-app/logs' || true",

      # Start the CloudWatch Agent
      "sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a start -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json",
      "sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a status",

    ]
  }


  # Step 7: Reload systemd, enable, and start the service
  provisioner "shell" {
    inline = [
      "sudo systemctl daemon-reload",
      "sudo systemctl enable app.service",
      "sudo systemctl start app.service"
    ]
  }
}
# In your Packer template `webapp-ami.pkr.hcl`
# build {
#   sources = [
#     "source.amazon-ebs.my-ami",
#   ]

#   provisioner "file" {
#     source      = "cloudwatch-config.json"
#     destination = "/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json"
#   }

#   provisioner "shell" {
#     inline = [
#       "/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a start -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json"
#     ]
#   }
# }
