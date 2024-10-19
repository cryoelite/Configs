#!/bin/bash
BASE_CONFIG_DIR=./Base_Config

apt-get update -y
apt-get upgrade -y
apt-get full-upgrade -y
apt-get clean

apt-get install -y docker.io nano
cd $BASE_CONFIG_DIR

touch .env
echo "#Put environment variables here, check the $BASE_CONFIIG_DIR/docker-compose.yml for the variables needed" > .env
nano .env
docker-compose up -d

apt-get update -y
apt-get upgrade -y
apt-get full-upgrade -y
apt-get clean

echo "Finished. Do docker container attach <whatever container name you gave in .env> to attach"