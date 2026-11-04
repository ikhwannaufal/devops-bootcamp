#!/bin/bash
curl -fsSL https://get.docker.com | sh
id ssm-user &>/dev/null || useradd -m ssm-user
usermod -aG docker ssm-user

mkdir -p /opt/rackula/data
curl -fsSL https://raw.githubusercontent.com/RackulaLives/Rackula/main/deploy/docker-compose.persist.yml -o /opt/rackula/docker-compose.yml
chown 1001:1001 /opt/rackula/data

cd /opt/rackula
docker compose up -d
