#!/bin/bash

# Path to Firefox executable
FIREFOX="/usr/bin/firefox"

# Proxy configuration
PROXY_URL="http://parrot3846kro025812:b3yzhv91qqdu@x202.fxdx.in:18005"

# Function to check if Firefox executable exists
check_firefox() {
  if [ ! -x "$FIREFOX" ]; then
    echo "Error: Firefox executable not found at $FIREFOX"
    exit 1
  fi
}

# Function to create and open a Firefox profile
create_and_open_profile() {
  PROFILE_NAME=$1
  echo "Creating and opening $PROFILE_NAME with proxy..."

  # Create a new Firefox profile
  "$FIREFOX" -CreateProfile "$PROFILE_NAME"

  # Set proxy settings in the newly created profile's prefs.js file
  PROFILE_DIR="$(find ~/.mozilla/firefox -maxdepth 1 -type d -name "*.$PROFILE_NAME")"
  if [ -d "$PROFILE_DIR" ]; then
    echo "user_pref(\"network.proxy.type\", 1);" >> "$PROFILE_DIR/prefs.js"
    echo "user_pref(\"network.proxy.http\", \"$PROXY_URL\");" >> "$PROFILE_DIR/prefs.js"
    echo "user_pref(\"network.proxy.ssl\", \"$PROXY_URL\");" >> "$PROFILE_DIR/prefs.js"
    echo "user_pref(\"network.proxy.ftp\", \"$PROXY_URL\");" >> "$PROFILE_DIR/prefs.js"
    echo "user_pref(\"network.proxy.socks\", \"$PROXY_URL\");" >> "$PROFILE_DIR/prefs.js"
    echo "user_pref(\"network.proxy.socks_version\", 5);" >> "$PROFILE_DIR/prefs.js"
    echo "user_pref(\"network.proxy.socks_remote_dns\", true);" >> "$PROFILE_DIR/prefs.js"

    # Open Firefox with the newly created profile
    # Using -no-remote to allow multiple instances
    "$FIREFOX" -no-remote -P "$PROFILE_NAME" &

    echo "$PROFILE_NAME created and opened successfully."
  else
    echo "Error: Profile directory not found for $PROFILE_NAME"
  fi
}

# Check if the Firefox executable exists
check_firefox

# Create and open 10 profiles with the same HTTP proxy settings
for i in {1..10}
do
  PROFILE_NAME="Profile$i"
  create_and_open_profile "$PROFILE_NAME"
  # Wait a bit before starting the next profile to reduce system load spike
  sleep 2
done

echo "All profiles created and opened successfully."
