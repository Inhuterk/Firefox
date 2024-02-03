#!/bin/bash

# Path to Firefox executable
FIREFOX="/usr/bin/firefox"

# Proxy configuration
PROXY_HOST="x202.fxdx.in"
PROXY_PORT="18005"
PROXY_USERNAME="parrot3846kro025812"
PROXY_PASSWORD="b3yzhv91qqdu"

# Check if the Firefox executable exists
if [ ! -x "$FIREFOX" ]; then
  echo "Firefox executable not found at $FIREFOX"
  exit 1
fi

# Create and open 10 profiles with proxy settings
for i in {1..10}
do
  PROFILE_NAME="Profile$i"
  echo "Creating and opening $PROFILE_NAME with proxy..."

  # Create a new Firefox profile
  "$FIREFOX" -CreateProfile "$PROFILE_NAME"

  # Set proxy settings in the newly created profile's prefs.js file
  PROFILE_DIR="$(find ~/.mozilla/firefox -maxdepth 1 -type d -name "*.$PROFILE_NAME")"
  echo "user_pref(\"network.proxy.type\", 1);" >> "$PROFILE_DIR/prefs.js"
  echo "user_pref(\"network.proxy.http\", \"$PROXY_HOST\");" >> "$PROFILE_DIR/prefs.js"
  echo "user_pref(\"network.proxy.http_port\", $PROXY_PORT);" >> "$PROFILE_DIR/prefs.js"
  echo "user_pref(\"network.proxy.ssl\", \"$PROXY_HOST\");" >> "$PROFILE_DIR/prefs.js"
  echo "user_pref(\"network.proxy.ssl_port\", $PROXY_PORT);" >> "$PROFILE_DIR/prefs.js"
  echo "user_pref(\"network.proxy.ftp\", \"$PROXY_HOST\");" >> "$PROFILE_DIR/prefs.js"
  echo "user_pref(\"network.proxy.ftp_port\", $PROXY_PORT);" >> "$PROFILE_DIR/prefs.js"
  echo "user_pref(\"network.proxy.socks\", \"$PROXY_HOST\");" >> "$PROFILE_DIR/prefs.js"
  echo "user_pref(\"network.proxy.socks_port\", $PROXY_PORT);" >> "$PROFILE_DIR/prefs.js"
  echo "user_pref(\"network.proxy.socks_version\", 5);" >> "$PROFILE_DIR/prefs.js"
  echo "user_pref(\"network.proxy.socks_remote_dns\", true);" >> "$PROFILE_DIR/prefs.js"
  echo "user_pref(\"network.proxy.socks_username\", \"$PROXY_USERNAME\");" >> "$PROFILE_DIR/prefs.js"
  echo "user_pref(\"network.proxy.socks_password\", \"$PROXY_PASSWORD\");" >> "$PROFILE_DIR/prefs.js"

  # Open Firefox with the newly created profile
  # Using -no-remote to allow multiple instances
  "$FIREFOX" -no-remote -P "$PROFILE_NAME" &

  # Wait a bit before starting the next profile to reduce system load spike
  sleep 2
done

echo "Profiles created and opened successfully."
