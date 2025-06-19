#!/bin/bash

#
# GitHub SSH Key and Repository Clone Script (v6)
#
# This script automates the process of setting up an SSH key for GitHub,
# cloning a repository, and setting up a development environment with
# Taskfile, Go, Lefthook, and Gitleaks.
#
# This version wraps the main logic in a function to reliably handle
# interactive input even when the script is piped from curl.
#

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
# The GitHub organization to clone from.
ORG_NAME="GuideToIceland"
# The default repository to clone if no argument is provided.
DEFAULT_REPO="monorepo"

# --- Helper Functions ---
# Prints a formatted header message.
print_header() {
    echo ""
    echo "=================================================================="
    echo "=> $1"
    echo "=================================================================="
}

# --- Main Logic Function ---
# This function contains all the interactive steps.
run_setup() {
    # --- Argument Handling ---
    # Use the first argument passed to the function, or fall back to the default.
    local REPO_NAME=${1:-$DEFAULT_REPO}
    local REPO_URL="git@github.com:${ORG_NAME}/${REPO_NAME}.git"

    print_header "GitHub SSH Key and Repo Setup"
    echo "This script will help you set up an SSH key and clone the '${REPO_NAME}' repository."
    echo "The script will stop immediately if any step fails."

    # 1. Get user's email for the SSH key
    echo ""
    read -p "Please enter the email address associated with your GitHub account: " USER_EMAIL

    if [ -z "$USER_EMAIL" ]; then
        echo "ERROR: Email cannot be empty. Aborting script." >&2
        exit 1
    fi

    # 2. Check for and generate SSH key if needed
    local SSH_KEY_PATH="$HOME/.ssh/id_ed25519"
    print_header "Step 1: Checking for SSH Key"

    if [ -f "${SSH_KEY_PATH}.pub" ]; then
        echo "An existing SSH key was found at ${SSH_KEY_PATH}.pub. We will use this key."
    else
        echo "No existing SSH key found. A new one will be generated."
        mkdir -p "$HOME/.ssh"
        chmod 700 "$HOME/.ssh"
        echo "Generating a new ED25519 SSH key..."
        ssh-keygen -t ed25519 -C "$USER_EMAIL" -f "$SSH_KEY_PATH" -N ""
        echo "Successfully generated a new SSH key."
    fi

    # 3. Instruct user to add the key to GitHub
    print_header "Step 2: ACTION REQUIRED - Add SSH Key to GitHub"
    echo "The script will now display your public SSH key."
    echo "You must add this key to your GitHub account before we can continue."
    echo ""
    echo "1. Copy the entire line of text below (it starts with 'ssh-ed25519...'):"
    echo ""
    cat "${SSH_KEY_PATH}.pub"
    echo ""
    echo "2. Open your browser and navigate to GitHub's SSH key settings:"
    echo "   https://github.com/settings/keys"
    echo ""
    echo "3. Click 'New SSH key', give it a title, and paste the key."
    echo ""
    read -p "Once you have added the key to GitHub, press [Enter] to continue..."

    # 4. Test the SSH connection to GitHub
    print_header "Step 3: Testing SSH Connection to GitHub"
    echo "Attempting to authenticate with GitHub..."
    echo "You may see a message asking to add GitHub to your list of known hosts. Please type 'yes' and press Enter if you do."
    echo ""

    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        echo ""
        echo "SUCCESS: You've successfully authenticated with GitHub."
    else
        echo ""
        echo "ERROR: Failed to authenticate with GitHub." >&2
        echo "Please check the following:" >&2
        echo "  1. Did you copy the ENTIRE public key?" >&2
        echo "  2. Did you paste it correctly into https://github.com/settings/keys?" >&2
        echo "  3. Wait a minute for the key to become active and try the script again." >&2
        exit 1
    fi

    # 5. Install Developer Tools (Taskfile)
    print_header "Step 4: Installing Developer Tools"
    echo "Installing Taskfile..."
    sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d
    echo "Taskfile installation command executed."

    # 6. Set up Go Environment and Tools
    print_header "Step 5: Setting up Go Environment & Tools"
    if ! command -v go &> /dev/null; then
        echo "WARNING: The 'go' command was not found. Skipping Go tool installation." >&2
        echo "Please install Go (https://go.dev/doc/install) and run the tool setup manually if needed." >&2
    else
        echo "Go installation found. Proceeding with setup..."
        local GO_PATH_LINE='export PATH=$PATH:$HOME/go/bin'
        local BASHRC_FILE="$HOME/.bashrc"

        echo "Updating shell configuration ($BASHRC_FILE) to include Go binary path..."
        if ! grep -qF "$GO_PATH_LINE" "$BASHRC_FILE"; then
            echo "" >> "$BASHRC_FILE"
            echo "# Add Go binary path for local tools" >> "$BASHRC_FILE"
            echo "$GO_PATH_LINE" >> "$BASHRC_FILE"
            echo "Go binary path added."
        else
            echo "Go binary path already exists in $BASHRC_FILE. No changes made."
        fi

        # Source the bashrc file to make the new PATH available in this session.
        # This ensures that binaries installed by 'go install' are found immediately.
        echo "Sourcing $BASHRC_FILE to update the current session's PATH..."
        # shellcheck disable=SC1090
        source "$BASHRC_FILE"

        echo ""
        echo "Installing Go tools..."
        go install github.com/SGudbrandsson/setup-env@latest
        # The gitleaks module path is different from its repository URL due to a migration.
        # We must use the path declared in its go.mod file.
        go install github.com/zricethezav/gitleaks/v8@latest
        go install github.com/evilmartians/lefthook@latest
        echo "Go tools installed successfully."
    fi

    # 7. Clone the repository
    print_header "Step 6: Cloning the Repository"
    echo "Attempting to clone '${REPO_URL}'..."
    echo ""
    git clone "$REPO_URL"

    # 8. Initialize Lefthook in the repository
    print_header "Step 7: Initializing Lefthook"
    if ! command -v lefthook &> /dev/null; then
        echo "WARNING: 'lefthook' command not found. Skipping lefthook initialization." >&2
    else
        echo "Changing directory to '$REPO_NAME' to install git hooks..."
        cd "$REPO_NAME"
        lefthook install
        echo "Lefthook git hooks installed successfully."
    fi

    print_header "Setup Complete!"
    echo "The repository '${REPO_NAME}' has been successfully cloned and configured."
    echo "You're all set!"
}

# --- Execution ---
# Execute the main function, passing all script arguments ($@) into it.
# Crucially, redirect the function's standard input from the system's terminal (/dev/tty).
# This ensures that 'read' commands work correctly even when the script is executed via a pipe.
run_setup "$@" < /dev/tty

exit 0
