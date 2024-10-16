#!/bin/bash
set -e

DIR="/opt/myapp"

sudo mkdir -p "${DIR}"

sudo useradd --system -s /usr/sbin/nologin csye6225
