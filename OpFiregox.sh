#!/bin/bash

# Path to Firefox executable
FIREFOX="/usr/bin/firefox"

# Check if the Firefox executable exists
if [ ! -x "$FIREFOX" ]; then
  echo "Firefox executable not found at $FIREFOX"
  exit 1
fi

# Create and open 10 profiles
for i in {1..10}
do
  PROFILE_NAME="Profile$i"
  echo "Creating and opening $PROFILE_NAME..."

  # Create a new Firefox profile
  "$FIREFOX" -CreateProfile "$PROFILE_NAME"

  # Open Firefox with the newly created profile
  # Using -no-remote to allow multiple instances
  "$FIREFOX" -no-remote -P "$PROFILE_NAME" &

  # Wait a bit before starting the next profile to reduce system load spike
  sleep 2
done

echo "Profiles created and opened successfully."
