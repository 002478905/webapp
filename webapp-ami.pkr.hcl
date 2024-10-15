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
  vpc_id       = "vpc-0f9abfd047eeac78c"
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
      "sudo systemctl start mysql",
      "sudo useradd -m -s /usr/sbin/nologin csye6225",
      "sudo groupadd csye6225",
      "sudo usermod -aG csye6225 csye6225"
    ]
  }

  provisioner "file" {
    source      = "webapp.zip"
    destination = "/tmp/webapp.zip"
  }

  provisioner "shell" {
    inline = [
      "sudo mkdir -p /opt/csye6225",
      "sudo unzip /tmp/webapp.zip -d /opt/csye6225",
      "sudo chown -R csye6225:csye6225 /opt/csye6225",
      "cd /opt/csye6225",
      "sudo -u csye6225 npm install",
      "sudo npm install -g pm2",
      "sudo -u csye6225 pm2 startup systemd",
      "sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u csye6225 --hp /home/csye6225",
      "sudo -u csye6225 pm2 start app.js",
      "sudo -u csye6225 pm2 save",
      "sudo systemctl enable pm2-csye6225"
    ]
  }

  provisioner "file" {
    content     = <<EOF
[Unit]
Description=PM2 process manager
Documentation=https://pm2.keymetrics.io/
After=network.target

[Service]
Type=forking
User=csye6225
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
Environment=PATH=/usr/bin:/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin
Environment=PM2_HOME=/home/csye6225/.pm2
PIDFile=/home/csye6225/.pm2/pm2.pid
Restart=on-failure

ExecStart=/usr/lib/node_modules/pm2/bin/pm2 resurrect
ExecReload=/usr/lib/node_modules/pm2/bin/pm2 reload all
ExecStop=/usr/lib/node_modules/pm2/bin/pm2 kill

[Install]
WantedBy=multi-user.target
EOF
    destination = "/tmp/pm2.service"
  }

  provisioner "shell" {
    inline = [
      "sudo mv /tmp/pm2.service /etc/systemd/system/pm2.service",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable pm2.service"
    ]
  }
}