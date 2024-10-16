#!/bin/bash
set -e

sudo cp /tmp/app /opt/myapp/app
sudo cp /tmp/csye6225.service /etc/systemd/system/csye6225.service
sudo cp /tmp/app.properties /opt/myapp/app.properties

sudo systemctl daemon-reload
sudo systemctl enable csye6225

sudo chown -R csye6225:csye6225 /opt/myapp
