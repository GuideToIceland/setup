#!/bin/bash

#
# GitHub SSH Key and Repository Clone Script
#
# This script automates the process of setting up an SSH key for GitHub
# and cloning a repository from the GuideToIceland organization.
#
# Usage:
#   ./setup.sh [repository_name]
#
# If no repository_name is provided, it defaults to 'monorepo'.
#

# --- Configuration ---
# The GitHub organization to clone from.
ORG_NAME="GuideToIceland"
# The default repository to clone if no argument is provided.
DEFAULT_REPO="monorepo"

# --- Helper Functions ---
# Prints a formatted header message.
print_header() {
    echo ""
    echo "------------------------------------------------------------------"
    echo "$1"
    echo "------------------------------------------------------------------"
}

# --- Argument Handling ---
# Use the first argument as the repository name, or fall back to the default.
REPO_NAME=${1:-$DEFAULT_REPO}
REPO_URL="git@github.com:${ORG_NAME}/${REPO_NAME}.git"

# --- Script Start ---
print_header "GitHub SSH Key and Repo Setup"
echo "This script will help you set up an SSH key and clone the '${REPO_NAME}' repository."

# 1. Get user's email for the SSH key
# The email is required for the `ssh-keygen` command.
# We must redirect input from /dev/tty to ensure this works when piping from curl.
read -p "Please enter the email address associated with your GitHub account: " USER_EMAIL < /dev/tty

if [ -z "$USER_EMAIL" ]; then
    echo "Email cannot be empty. Aborting script."
    exit 1
fi

# 2. Check for and generate SSH key if needed
SSH_KEY_PATH="$HOME/.ssh/id_ed25519"
print_header "Step 1: Checking for SSH Key"

if [ -f "${SSH_KEY_PATH}.pub" ]; then
    echo "An existing SSH key was found at ${SSH_KEY_PATH}.pub."
    echo "We will use this key."
else
    echo "No existing SSH key found. A new one will be generated."
    # Ensure the .ssh directory exists and has the correct permissions.
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    
    # Generate the key without any interactive prompts for file location or passphrase.
    # This is equivalent to accepting the defaults by pressing Enter.
    echo "Generating a new ED25519 SSH key..."
    ssh-keygen -t ed25519 -C "$USER_EMAIL" -f "$SSH_KEY_PATH" -N ""
    
    if [ $? -eq 0 ]; then
        echo "Successfully generated a new SSH key."
    else
        echo "Error: Failed to generate SSH key. Please check for errors and try again."
        exit 1
    fi
fi

# 3. Instruct user to add the key to GitHub
# This is a manual step that the script cannot perform automatically.
print_header "Step 2: ACTION REQUIRED - Add SSH Key to GitHub"
echo "The script will now display your public SSH key."
echo "You must add this key to your GitHub account before we can clone the repository."
echo ""
echo "1. Copy the entire line of text below (it starts with 'ssh-ed25519...'):"
echo ""

# Display the public key for the user to copy.
cat "${SSH_KEY_PATH}.pub"

echo ""
echo "2. Open your browser and navigate to GitHub's SSH key settings:"
echo "   https://github.com/settings/keys"
echo ""
echo "3. Click the 'New SSH key' button."
echo "4. Give it a descriptive title (e.g., 'My Development Machine')."
echo "5. Paste the key you copied into the 'Key' text box and click 'Add SSH key'."
echo ""

# Pause the script and wait for the user to complete the manual step.
# We must also redirect this read command from /dev/tty.
read -p "Once you have added the key to GitHub, press [Enter] to continue..." < /dev/tty

# 4. Clone the repository
print_header "Step 3: Cloning the Repository"
echo "Attempting to clone '${REPO_URL}'..."
echo "If this fails, please ensure you correctly added the SSH key to your GitHub account."
echo ""

git clone "$REPO_URL"

if [ $? -eq 0 ]; then
    print_header "Setup Complete!"
    echo "The repository '${REPO_NAME}' has been successfully cloned into the current directory."
    echo "You're all set to go!"
else
    print_header "Error during clone"
    echo "Failed to clone the repository."
    echo "Please double-check the following:"
    echo "  1. The SSH key was correctly added to https://github.com/settings/keys"
    echo "  2. The repository '${REPO_NAME}' exists in the '${ORG_NAME}' organization."
    echo "  3. You have the necessary permissions to access the repository."
    exit 1
fi

exit 0
