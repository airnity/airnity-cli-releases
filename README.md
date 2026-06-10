# Airnity CLI

This project aims to simplify the Airnity developer life.

It is a Command Line Interface to automate several boring and repetitive tasks.

## Install

To install `airnity` cli, go to the [Release Page](https://github.com/airnity/airnity-cli-releases/releases), and download the binary corresponding to your architecture.

You can then rename the binary to its original name: `airnity` (or `airnity.exe` on windows), and move it to a place in your `$PATH` (eg: `~/.local/bin`)

Then on mac and linux you need to change the permission to be able to execute it.

<!-- x-release-please-start-version -->

```shell
# Example for MacOS
mv airnity-darwin-arm64 ~/.local/bin/airnity
chmod +x ~/.local/bin/airnity
# then use it with `airnity --help`
```

```shell
# Example for Linux
mv airnity-linux-amd64 ~/.local/bin/airnity
chmod +x ~/.local/bin/airnity
# then use it with `airnity --help`
```

```shell
# Example for Windows PowerShell (Run as Administrator)
# Go in your download folder
Copy-Item "airnity-windows-amd64.exe" "$env:WINDIR\System32\airnity.exe"
# then use it with `airnity.exe --help`
```

<!-- x-release-please-end -->

You are good to go!

## External Requirements

This binary requires the following tools and components to be installed:

1. **Google Cloud SDK (`gcloud`)**

   The `gcloud` command-line tool is essential for interacting with Google Cloud services.
   - [Installation Guide](https://cloud.google.com/sdk/docs/install)

2. **`gke-gcloud-auth-plugin` Component**

   Required for authenticating with Google Kubernetes Engine (GKE).

   ```shell
   gcloud components install gke-gcloud-auth-plugin
   ```

3. **GitHub CLI (`gh`)** _(optional)_

   Used by the interactive TUI to authenticate GitHub API calls (via `gh auth token`). Alternatively, set `$GITHUB_TOKEN`.
   - [Installation Guide](https://cli.github.com/)

4. **GPG (`gpg`)** _(optional)_

   Required for the `airnity gpg generate` command.
   - Usually pre-installed on macOS and Linux. On macOS you can install it via `brew install gnupg`.

## Config Management

The `airnity` CLI uses the config file `${HOME}/.airnity.yaml`, which is created with default values if it doesn't exist.

### Displaying the Current Configuration

You can display the current configuration using the `config get` command:

```shell
airnity config get
```

You can customize the newly created `${HOME}/.airnity.yaml` as needed.

## Commands

The Airnity CLI provides various commands organized by functionality:

### Version Information

```shell
airnity version
```

Display version information including git commit and build details.

### Authentication

The CLI manages two independent auth systems: **Keycloak** (internal SSO) and **GCloud**.

#### Unified Login/Logout

```shell
# Authenticate with both Keycloak and GCloud
airnity login

# Authenticate with Keycloak only
airnity login -k

# Authenticate with GCloud only
airnity login -g

# Logout from both Keycloak and GCloud
airnity logout

# Logout from Keycloak only
airnity logout -k

# Logout from GCloud only
airnity logout -g
```

#### Keycloak Auth

```shell
# Authenticate with Keycloak (OAuth2 + PKCE)
airnity auth login

# Force re-authentication
airnity auth login -f

# Logout from Keycloak
airnity auth logout

# Show current authenticated user
airnity auth whoami

# Check authentication status
airnity auth status

# Print access token to stdout (useful for manual API calls)
airnity auth print-access-token

# Show raw token details (debug)
airnity auth debug-tokens
```

#### GCloud Auth

```shell
# Check and authenticate GCloud credentials
airnity gcloud login

# Revoke GCloud tokens
airnity gcloud logout
```

### Configuration Management

```shell
# Display current configuration
airnity config get

# Set individual configuration values
airnity config set k8s.kubeconfigPath "~/.kube/custom-config"
airnity config set ai.bifrostUrl "https://bifrost.airnity.io/anthropic"
```

The `config set` command allows you to update individual configuration values using dot notation for nested keys. Valid keys are:

- `editor`: Editor used by the CLI
- `k8s.kubeconfigPath`: Path to your Kubernetes config file
- `ai.bifrostUrl`: Bifrost API base URL

### Kubernetes Management

```shell
# List all available Kubernetes clusters
airnity k8s list clusters

# Generate kubeconfig files for all clusters
airnity k8s get kubeconfigs

# Use private endpoints for GKE clusters
airnity k8s get kubeconfigs --private-endpoints
```

### Docker Registry

```shell
# Login to GCP Docker registries
airnity docker login
```

### AI-Powered Developer Tools

```shell
# Generate an AI-powered commit message from staged changes
airnity ai commit

# Use a specific model
airnity ai commit --model claude-sonnet

# Show detailed context sent to AI
airnity ai commit -v
```

The `ai commit` command analyzes staged git changes and generates conventional commit messages using Claude via Bifrost.

### Claude Code Configuration

```shell
# Install the bifrost MCP server and configure ~/.claude/settings.json
airnity claude configure

# Toggle MCP servers on/off for the current project
airnity claude mcp manage
```

The `claude` command manages Claude Code configuration: bifrost MCP setup and per-project MCP server permissions (written to `.claude/settings.local.json`).

### Argo Render & Diff

Run these from inside an `argo-*` repository.

```shell
# Stream every (app, cluster) variant as a multi-document YAML
airnity argo render

# Filter by app and/or cluster (both flags are repeatable)
airnity argo render --app my-app --cluster my-cluster

# Diff origin/main against your merged working tree
airnity argo diff

# Open the diff in difit (browser)
airnity argo diff --browser
```

The `argo` command mirrors the TUI's Argo Render / Argo Diff tabs from the command line.

### Airnity Root CA Certificate

```shell
# Show whether the Airnity Root CA is trusted system-wide
airnity cert status

# Install the Airnity Root CA into the OS trust store (requires sudo/admin)
airnity cert install
```

The `cert` command manages trust of the embedded Airnity Root CA, required to access `*.airnity.private` URLs.

### Wazuh Security Management

```shell
# Configure and enroll Wazuh agent
airnity wazuh configure

# Display real-time Wazuh agent logs
airnity wazuh print-logs

# Display current Wazuh agent configuration
airnity wazuh print-config

# Display Wazuh agent version
airnity wazuh version
```

### CLI Updates

```shell
# Upgrade to the latest version
airnity upgrade

# Use custom proxy for updates
airnity upgrade --proxy-url https://my-proxy.example.com
```

### Git Hooks Management

```shell
# Check git hooks installation status
airnity githooks status

# Install global git hooks (automatically configures Git)
airnity githooks install

# Create a backup of current git hooks
airnity githooks backup

# Remove global git hooks
airnity githooks uninstall
```

The `githooks` command manages global git hooks that automate common development tasks for Airnity repositories. These hooks help maintain consistent development workflows and standards.

**Important Note**: When git hooks are configured globally via `core.hooksPath`, they completely override repository-level hooks in `.git/hooks`. This is why the `airnity githooks` command installs all standard git hook files - even if a specific hook doesn't perform any action, it must exist to allow repository-level hooks to be called through the `run-repo-hook` mechanism.

#### Features

- **Automatic Ticket Number Insertion**: Extracts ticket numbers from branch names and appends them to commit messages
  - Branch pattern `tid-123-feature-description` -> Commit message gets `(tid#123)` appended
  - Branch pattern `bid-456-bug-fix` -> Commit message gets `(bid#456)` appended
- **Organization Filtering**: Only executes for repositories in the `airnity` GitHub organization
- **Smart Detection**: Won't duplicate ticket numbers if already present in the commit message
- **Repository Hook Integration**: Allows individual repositories to override or extend global hooks

#### Subcommands

- **`status`**: Shows whether git hooks are installed, their location, installation date, and any missing hook files
- **`install`**: Creates `~/.githooks` directory, installs all necessary hook files with proper permissions, and automatically configures Git to use them globally (`git config --global core.hooksPath ~/.githooks`)
- **`backup`**: Creates a timestamped backup of your current git hooks configuration (useful before making changes)
- **`uninstall`**: Removes the global git hooks installation completely

The git hooks are installed globally in your HOME directory (`~/.githooks`) and work with all Git repositories in your user account. The installation process automatically configures Git to use these hooks globally.

## GPG Keys Generation

```shell
airnity gpg generate
```

The `gpg generate` command automates the creation of a GPG keypair along with subkeys for signing, encryption, and authentication. This process isolates the keys within a temporary `GNUPGHOME` directory, ensuring your default keyring remains untouched. The command will:

- Generate a new master key for certification.
- Generate subkeys for signing, encryption, and authentication.
- Export the master key, subkeys, and public key to `.key` files
- Generate a revocation certificate
- Copy the generated passphrase to your clipboard for secure storage.

Once the key generation process is complete, the following files will be available in the temporary directory displayed by the script (e.g., `/tmp/gnupg_202410141642_Fo2GaO`):

- **`master.key`**: This is your master secret key. **Do not** share this key with anyone.
- **`sub.key`**: This contains your secret subkeys for signing, encryption, and authentication.
- **`pub.key`**: This is your public key. You can share this with anyone who needs to encrypt messages to you or verify your signatures.
- **`revoke.asc`**: This is a revocation certificate that can be used to invalidate your keys if they are ever compromised or lost.

### Next Steps: Storing Keys/Passphrase & import into your keyring

To save, import the keys into your keyring and verify that it is working, you can follow the documentation here :
https://airnity.fibery.io/Knowledge_Management/How_to/Generate-and-manage-your-GPG-keys-153/anchor=Backup--c7b633bb-103c-4934-94ca-e4456b267071

For the cleanup part you just have to delete the folder mentioned above (e.g., `/tmp/gnupg_202410141642_Fo2GaO`)
