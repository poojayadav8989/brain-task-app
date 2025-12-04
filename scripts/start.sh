#!/bin/bash
echo "Starting Docker container..."
cd /home/ec2-user/app
docker compose down
docker compose up -d
