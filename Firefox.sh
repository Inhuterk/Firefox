#!/bin/bash

# Base directory where profiles will be created
BASE_DIR="$HOME/firefox_profiles"

# Number of profiles to create
NUM_PROFILES=10

# Ensure the base directory exists
mkdir -p "$BASE_DIR"

# Create profiles
for i in $(seq 1 $NUM_PROFILES); do
    PROFILE_DIR="$BASE_DIR/profile_$i"
    mkdir -p "$PROFILE_DIR"
    
    # Create a profile with the firefox command
    firefox --no-remote -CreateProfile "profile_$i $PROFILE_DIR"

    # Launch Firefox with the created profile
    firefox --no-remote --profile "$PROFILE_DIR" &
done

echo "$NUM_PROFILES Firefox profiles have been created and launched."
