# Airnity CLI

This project aims to simplify the Airnity developer life.

It is a Command Line Interface to automate several boring and repetitive tasks.

## Install

To install `airnity` cli, go to the [Release Page](https://github.com/airnity/airnity-cli-releases/releases), and download the binary corresponding to your architecture.

You can then rename the binary to its original name: `airnity` (or `airnity.exe` on windows), and move it to a place in your `$PATH` (eg: `~/.local/bin`)

### For mac users

```shell
# Open Terminal app
# You are now in your $HOME folder
# Check if you have a ".local/bin" folder
ls .local/bin # (Press Enter)
# if you get a "not found" message create the folder hierarchy
mkdir -p .local/bin # (Press Enter)
# Add this new folder to the list of folders known for containing binaries
echo "export PATH=$HOME/.local/bin:$PATH" >> .zshrc # (Press Enter)
# Go in your download folder
cd ~/Downloads # (Press Enter)
# Move and rename binary
mv airnity-darwin-arm64 ~/.local/bin/airnity # (Press Enter)
# Change permissions to make it executable
chmod +x ~/.local/bin/airnity # (Press Enter)
# then use it with `airnity --help`
```

### For linux users

```shell
# Go in your download folder
cd ~/Downloads
# Move and rename binary
mv airnity-linux-amd64 ~/.local/bin/airnity # (Press Enter)
# Change permissions
chmod +x ~/.local/bin/airnity # (Press Enter)
# then use it with `airnity --help`
```

### For windows users

```shell
# Open Windows PowerShell (Run as Administrator)
# Go in your download folder 
cd $env:USERPROFILE\Downloads # (Press Enter)
# Move and rename binary
Copy-Item "airnity-windows-amd64.exe" "$env:WINDIR\System32\airnity.exe" # (Press Enter)
# then use it with `airnity.exe --help`
```

You are good to go!

## External Requirements (Only for GCP and clusters access)

This binary requires the following tools and components to be installed:

1. **Google Cloud SDK (`gcloud`)**

   The `gcloud` command-line tool is essential for interacting with Google Cloud services.

   - [Installation Guide](https://cloud.google.com/sdk/docs/install)

2. **`gke-gcloud-auth-plugin` Component**

   Required for authenticating with Google Kubernetes Engine (GKE).

   ```shell
   gcloud components install gke-gcloud-auth-plugin
   ```

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

### Configuration Management

```shell
# Display current configuration
airnity config get

# Set individual configuration values
airnity config set username "john.doe"
airnity config set wazuh.enrollmentPassword "mypassword"
airnity config set k8s.kubeconfigPath "~/.kube/custom-config"
```

The `config set` command allows you to update individual configuration values. Valid keys include:
- `username`: Your Airnity username (e.g john.doe if your email is john.doe@airnity.com)
- `k8s.kubeconfigPath`: Path to your Kubernetes config file
- `wazuh.enrollmentPassword`: Password for Wazuh agent enrollment

### Kubernetes Management

```shell
# List all available Kubernetes clusters
airnity k8s list clusters

# Generate kubeconfig files for all clusters
airnity k8s get kubeconfigs

# Use private endpoints for GKE clusters
airnity k8s get kubeconfigs --private-endpoints
```

### Authentication

```shell
# Check and authenticate GCloud credentials
airnity auth login

# Revoke GCloud tokens
airnity auth logout
```

### Docker Registry

```shell
# Login to GCP Docker registries
airnity docker login
```

### Wazuh Security Management

```shell
# Configure and enroll Wazuh agent
airnity wazuh configure

# Display real-time Wazuh agent logs
airnity wazuh print-logs

# Display current Wazuh agent configuration
airnity wazuh print-config

# Display current Wazuh agent version
airnity wazuh version
```

### CLI Updates

```shell
# Upgrade to the latest version
airnity upgrade

# Use custom proxy for updates
airnity upgrade --proxy-url https://my-proxy.example.com
```

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

After key generation, securely store your master key and passphrase. Import the keys into your keyring and verify they're working properly.

For cleanup, delete the temporary folder mentioned above (e.g., `/tmp/gnupg_202410141642_Fo2GaO`).
