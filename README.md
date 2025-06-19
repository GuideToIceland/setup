# GitHub SSH Key and Repository Setup Script

This script is designed to streamline the initial setup process for developers joining a project. It automates the creation of an SSH key, provides instructions for adding it to GitHub, and clones a specified repository from the `GuideToIceland` organization.

## Features

- **Interactive Setup**: Prompts the user for the email address associated with their GitHub account.
- **SSH Key Management**:
    - Checks if an `id_ed25519` SSH key already exists.
    - If no key is found, it generates a new one automatically.
- **Guided GitHub Integration**: Displays the new public SSH key and provides clear, step-by-step instructions for adding it to the user's GitHub account settings.
- **Flexible Repository Cloning**:
    - Clones a specific repository from the `GuideToIceland` organization by passing its name as an argument.
    - If no repository name is provided, it defaults to cloning `monorepo`.
- **User-Friendly**: Provides clear headers and status messages, guiding the user through each step of the process.

## Prerequisites

Before running this script, ensure you have the following command-line tools installed on your system:

- `git`
- `ssh-keygen`
- `curl` (if you plan to run the script directly from a URL)

## Usage

There are two primary ways to use this script: running it from a local file or executing it directly from a remote URL.

### 1. Local Execution

1.  **Save the Script**: Save the script content into a file named `setup.sh`.

2.  **Make it Executable**: Open your terminal and grant execute permissions to the file:
    ```bash
    chmod +x setup.sh
    ```

3.  **Run the Script**:
    - To clone the default repository (`monorepo`):
      ```bash
      ./setup.sh
      ```
    - To clone a different repository (e.g., `guide`):
      ```bash
      ./setup.sh guide
      ```

### 2. Remote Execution via `curl`

You can run this script directly from its raw GitHub URL without downloading it first. This is a convenient way to share and run the setup process.

1.  **Get the Raw URL**: Navigate to the script file in the GitHub repository and click the **"Raw"** button to get the direct link to the file.

2.  **Run the Command**:
    - To run the script and clone the default repository (`monorepo`):
      ```bash
      curl -sS [https://raw.githubusercontent.com/GuideToIceland/setup/main/setup.sh](https://raw.githubusercontent.com/GuideToIceland/setup/main/setup.sh) | bash
      ```
    - To pass an argument and clone a specific repository (e.g., `guide`):
      ```bash
      curl -sS [https://raw.githubusercontent.com/GuideToIceland/setup/main/setup.sh](https://raw.githubusercontent.com/GuideToIceland/setup/main/setup.sh) | bash -s guide
      ```

## How It Works

1.  **Argument Handling**: The script first checks if an argument (a repository name) was provided. If not, it sets `monorepo` as the default target.
2.  **Email Prompt**: It asks for your GitHub-associated email, which is used to label the new SSH key.
3.  **SSH Key Check**: It looks for an existing public key at `~/.ssh/id_ed25519.pub`.
4.  **Key Generation**: If no key is found, it runs `ssh-keygen` with the provided email to create a new key pair without a passphrase, accepting the default file location.
5.  **GitHub Instructions**: The script then displays the public key and pauses, instructing you to add it to your GitHub account. This is a crucial manual step.
6.  **Clone Repository**: After you confirm that the key has been added to GitHub by pressing Enter, the script proceeds to run `git clone` using the SSH URL for the target repository.
