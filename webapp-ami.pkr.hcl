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
  default = "ami-0866a3c8686eaeeba"
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
  region          = "${var.aws_region}"
  ami_name        = "csye6225-coursework-${formatdate("YYYY_MM_DD", timestamp())}"
  ami_description = "AMI for CSYE 6225"

  ami_regions = [
    "us-east-1",
  ]

  aws_polling {
    delay_seconds = 120
    max_attempts  = 50
  }

  instance_type = "t2.small"
  source_ami    = "${var.source_ami}"
  ssh_username  = "${var.ssh_username}"
  subnet_id     = "${var.subnet_id}"

  launch_block_device_mappings {
    delete_on_termination = true
    device_name           = "/dev/sda1"
    volume_size           = 8
    volume_type           = "gp2"
  }
}


build {
  sources = [
    "source.amazon-ebs.my-ami",
  ]
//   provisioner "shell" {
//     environment_vars = [
//       "DEBIAN_FRONTEND=noninteractive",
//       "CHECKPOINT_DISABLE=1"
//     ]

//     inline = [
//       "sudo apt-get update",
//       "sudo apt-get upgrade -y",
//       "sudo apt-get install nginx -y",
//       "sudo apt-get clean",
//     ]
//   }
// }

provisioner "shell"{
  script ="updateOs.sh"
}
provisioner "shell"{
  script ="appDirSetup.sh"
}
provisioner "file" {
  source      = "app.properties"
  destination = "/tmp/app.properties"
}

provisioner "file" {
  source      = "app"
  destination = "/tmp/app"
}

provisioner "file" {
  source      = "app.service"
  destination = "/tmp/app.service"
}

