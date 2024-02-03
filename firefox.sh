#!/bin/bash

# Path to Firefox executable
# Update this path according to where Firefox is installed on your system
FIREFOX="/usr/bin/firefox"

# Check if the Firefox binary exists
if [ ! -x "$FIREFOX" ]; then
  echo "Firefox executable not found at $FIREFOX"
  exit 1
fi

# Create 10 profiles
for i in {1..10}
do
  PROFILE_NAME="Profile$i"
  echo "Creating $PROFILE_NAME..."
  # Create a new Firefox profile without starting Firefox
  "$FIREFOX" -CreateProfile "$PROFILE_NAME"
done

echo "Profiles created successfully."
