# Airnity CLI

This project aims to simplify the Airnity developer life.

It is a Command Line Interface to automate several boring and repetitive tasks.

## Install

Auto-detects your OS and architecture, downloads the latest release, and installs it (to `~/.local/bin` on macOS/Linux, or `%LOCALAPPDATA%\airnity\bin` on Windows):

```shell
# macOS / Linux
curl -fsSL https://raw.githubusercontent.com/airnity/airnity-cli-releases/main/install.sh | sh
```

```powershell
# Windows PowerShell
irm https://raw.githubusercontent.com/airnity/airnity-cli-releases/main/install.ps1 | iex
```

On macOS/Linux make sure `~/.local/bin` is in your `$PATH` (the Windows script adds its dir to your PATH automatically). Once installed, upgrade later with `airnity upgrade`.

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

5. **`psql` client** _(optional — only for `airnity db connect psql` / `db browse`'s `d`)_

   The PostgreSQL command-line client. Not required for `db connect proxy`, `db connect pgadmin`, or `db query`.
   - macOS: `brew install libpq` (then add it to your `PATH`, e.g. `brew link --force libpq`), or `brew install postgresql@16`.
   - Debian/Ubuntu: `sudo apt install postgresql-client`
   - Fedora/RHEL: `sudo dnf install postgresql`

6. **pgAdmin** _(optional — only for `airnity db connect pgadmin` / `db browse`'s `g`)_

   See the [Database Management requirements](#requirements) below for the full setup (desktop app **and** server package, plus a one-time first launch).
   - [Download pgAdmin](https://www.pgadmin.org/download/)

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

#### Local HTTP Server

```shell
# Start a local HTTP server on 127.0.0.1:47823 (Ctrl+C to stop)
airnity serve

# Override the default port
airnity serve --port 9001

# From another terminal, once running:
curl http://127.0.0.1:47823/auth/token
```

### Configuration Management

```shell
# Display current configuration
airnity config get

# Set individual configuration values
airnity config set k8s.kubeconfigPath "~/.kube/custom-config"
airnity config set ai.bifrostUrl "https://bifrost.airnity.io/anthropic"

# Register this machine's Tailscale IP with the IDP backend
airnity config register-tailscale-ip            # auto-detects via `tailscale ip -4`
airnity config register-tailscale-ip 100.1.2.3  # or pass the IP explicitly
```

The `config set` command allows you to update individual configuration values using dot notation for nested keys. Valid keys are:

- `editor`: Editor used by the CLI
- `k8s.kubeconfigPath`: Path to your Kubernetes config file
- `ai.bifrostUrl`: Bifrost API base URL

The `config register-tailscale-ip` command registers this machine's Tailscale IP with the IDP backend. With no argument the IP is auto-detected by running `tailscale ip -4`; pass an explicit IP to override detection.

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

### Database Management

Connect to Cloud SQL and AlloyDB instances over a local, IAM-authenticated proxy — no
passwords, no IP allow-listing. Find a target with `db list`, then either `db query` for
headless SQL, `db connect proxy/psql/pgadmin` for a direct connection, or `db browse` for
an interactive picker. The command name alone decides whether you get a picker — no flag
ever changes which of these you get.

```shell
# Interactive: browse instances and their databases, then choose an action
airnity db browse
```

#### Discovery

```shell
# Every instance you can connect to
airnity db list instances
airnity db list instances backend

# Databases across every instance you can reach, with your write-access status on each
airnity db list databases
airnity db list databases boss
airnity db list databases --instance backend-prod
```

- **`db list instances [pattern]`** — every Cloud SQL / AlloyDB instance you can connect
  to, one row per instance: project, engine, instance, region. `pattern` is a
  case-insensitive substring of the instance name.
- **`db list databases [pattern] [--instance <substring>]`** — the databases inside every
  Cloud SQL / AlloyDB instance you can connect to, one row per database: project, engine,
  instance, database, region, and a `Write` column (`writable`, `granted (expires in
  <duration>)`, `pending`, or empty). `pattern` is a case-insensitive substring of the
  database name; `--instance` narrows to instances whose name contains it, and errors if it
  names no instance you can reach. No row limit — narrow with the pattern.

If you name an instance you cannot reach explicitly (`--instance`, `db query`, `db connect
…`), the error explains why: selfservice-database-rw has not resolved a connection target
for it yet. Nothing here re-implements access control — selfservice-database-rw is the
sole authority on which databases you may read; this CLI only asks it and reports what it
says.

A pattern matching nothing suggests up to 5 nearest names by edit distance instead of
returning an empty list:

```shell
$ airnity db list databases bifrsot
no database matching "bifrsot" — nearest: bifrost, ...
```

#### Connecting

```shell
# Headless SQL — no psql, no local port, scriptable
airnity db query --instance core-prod-primary --db boss "select count(*) from users"

# A local proxy in front of the whole instance, held open until Ctrl+C
airnity db connect proxy --instance core-prod-primary
airnity db connect proxy --instance core-prod-primary --db boss
airnity db connect proxy --instance core-prod-primary --port 5433

# An interactive psql session (needs a terminal)
airnity db connect psql --instance core-prod-primary --db boss

# pgAdmin, imported and launched automatically
airnity db connect pgadmin --instance core-prod-primary
```

- **`db query --instance <name> --db <name> "<sql>"`** — runs the SQL in-process (no `psql`
  install, no local port, no terminal) and prints the result. Both flags are required. The
  SQL is a required positional argument; pass `-` to read it from stdin instead. There is
  no read-only restriction — anything `psql` could run, this can too.
- **`db connect proxy --instance <name> [--db <name>] [--port <n>]`** — starts the proxy and
  prints a ready-to-paste connection string, then blocks until interrupted (`Ctrl+C` or a
  signal). It fronts the whole instance — the printed database can be swapped for any other
  one on it via the connection string's `dbname=...`. `--db` only sets which one the printed
  strings default to (defaulting to `postgres` itself when omitted); `--port` picks a fixed
  local port instead of a random one. A proxy that failed to connect exits with the
  underlying cause instead of `0`.
- **`db connect psql --instance <name> --db <name>`** — opens an interactive `psql` session.
  Needs a terminal and never falls back to a picker; for scripted SQL use `db query`
  instead.
- **`db connect pgadmin --instance <name>`** — imports the instance as a server into pgAdmin
  and launches it, holding the proxy open until you close pgAdmin (or press `Ctrl+C`).
  pgAdmin browses every database itself, which is why this acts on the whole instance rather
  than one database. Works with the Linux/WSL package (`pgadmin4` on `PATH`) and with the
  macOS application bundle, including `brew install --cask pgadmin4`, which puts no
  `pgadmin4` on `PATH`. Launch pgAdmin once before first use so its config database exists.

`--instance` takes the name as `db list databases` shows it (for AlloyDB, the instance
alone) or the full `cluster/instance` form; it errors if the name is unknown, matches more
than one instance, or you lack access to it, and supports shell completion (a live,
bounded query to selfservice-database-rw — TAB simply offers nothing if it's slow or
unauthenticated).

The commands that print data — `db list databases`, `db query`,
`db connect proxy` — also accept `-o json`, which always
prints exactly one JSON object on stdout, on both success and failure, with the exit code
carrying the verdict; their text output is a table with a header, or a header-only TSV
when piped. `db browse`, `db connect psql` and `db connect pgadmin` hand the terminal to a
UI instead of printing data, so they reject `-o json` naming the command that does what
you wanted rather than accepting it and printing prose anyway. A command missing its
target (e.g. `db query` without `--instance`/`--db`, or `db connect psql` with no terminal
attached) fails with a message naming the exact command to run instead — it never falls
back to `db browse`.

#### `db browse`

The only picker: a two-pane TUI listing every instance you can reach and, once one is
focused, its databases.

```text
╭─ instances ─────────────────╮ ╭─ databases in backend-prod  (6 databases) ─╮
│ ▸ alloydb   backend-prod    │ │   postgres                                 │
│   cloudsql  platform-prod   │ │ ▸ boss                                     │
│   alloydb   core-network-d… │ │   facteur                                  │
│   alloydb   platform-it     │ │   fedex                                    │
╰─────────────────────────────╯ ╰────────────────────────────────────────────╯
```

1. **Instance pane** — every instance you can connect to, and only those: every row is one
   the actions below work on. `→` or `enter` moves to the databases; `ctrl+r` re-queries
   selfservice-database-rw.
2. **Database pane** — `/` filters, `r` refreshes the focused instance's write-access status.
   `enter` on the highlighted database opens a popup to pick psql, pgAdmin, or a bare proxy
   (arrow keys move, `enter` confirms); press `d`, `g`, or `p` instead to skip the popup and
   commit straight away.
   These call the exact same functions as `db connect proxy/psql/pgadmin`.

   If a database shows a write-access status next to its name, `w` requests or revokes it
   right there — see [Temporary Write Access](#temporary-write-access).

3. **Proxy screen** (after `p`) — `↑↓` moves over the connection details and `enter` copies
   the highlighted one to the clipboard.
4. **Coming back.** Leaving psql (`ctrl+D` or `\q`), quitting pgAdmin, or pressing `esc` on
   the proxy screen hands the browser back with its caches intact, so trying another
   database costs no re-scan. `q` / `ctrl+c` tears down the proxy and quits for good. A
   session that ended because the connection failed exits with the cause rather than
   painting over it.

`db browse` takes no target flags; there is no `--instance`/`--db` to skip the picker —
find those with `db list` and reach for `db query` or `db connect` instead.

#### Troubleshooting connection failures

Set `AIRNITY_DB_DEBUG=1` to append connection diagnostics to `~/.airnity/db-debug.log`:
one line per `db list databases` call (duration and row count) plus
one line per failed connection dial (the connector's own error, verbatim). `db browse`'s
error screen then prints the log path.

```shell
AIRNITY_DB_DEBUG=1 airnity db browse
```

It writes to a file rather than the terminal because the browser is a full-screen TUI.
This is the fastest way to report a problem: the log holds the raw cause behind a failed
`db list databases` call or a failed proxy connection, neither of which
the browser itself shows.

#### Requirements

- Authenticated with gcloud (`airnity gcloud login`) — the proxy authenticates as your
  active gcloud account via IAM, so the matching database role must already exist on the
  instance. If your gcloud login or application-default credentials are missing or expired,
  every command that opens a session (`db connect`, `db query`, `db browse`) re-authenticates
  in place before connecting. `db list instances` and `db list databases` need no gcloud
  credentials at all — discovery answers from your Keycloak token alone.
- An interactive terminal for `db browse` and `db connect psql` (an interactive `psql`
  session needs one to attach to). `db query`, `db connect proxy`, and `db connect pgadmin`
  fully name the target and run without one. `--plain` / `--no-color` render `db browse`
  without color but don't disable it.

Each of psql and pgAdmin is its own external dependency, independent of the others — you
only need the tool for the command you actually use (`db connect proxy` and `db query`
need neither):

- **`db connect psql` / `db browse`'s `d`** — `psql` must be on your `PATH`. If it isn't,
  it fails with `psql not found — install PostgreSQL client tools`; pgAdmin, the proxy, and
  `db query` are unaffected (`db query` runs the SQL in-process, no `psql` involved).
  - macOS: `brew install libpq` (then `brew link --force libpq`), or `brew install postgresql@16`.
  - Debian/Ubuntu: `sudo apt install postgresql-client`
  - Fedora/RHEL: `sudo dnf install postgresql`

- **`db connect pgadmin` / `db browse`'s `g`** — needs a working pgAdmin **desktop**
  install, and specifically:
  1. The `pgadmin4` launcher on your `PATH` — otherwise `pgadmin4 not found on PATH`.
  2. The pgAdmin **server** files (`web/setup.py` and the bundled `venv`), i.e. the
     `pgadmin4-server` package — otherwise `pgAdmin server files not found … is pgadmin4-server installed?`.
  3. pgAdmin launched **once** beforehand, so its config database (`~/.pgadmin/pgadmin4.db`)
     exists — otherwise `pgAdmin desktop database not found … launch pgAdmin once first`.

  Install from the [pgAdmin download page](https://www.pgadmin.org/download/). On Debian/Ubuntu
  the `pgadmin4-desktop` package pulls in `pgadmin4-server`; after installing, run pgAdmin once
  and close it before connecting. Also quit pgAdmin before connecting — the import step needs
  exclusive access to its config database.

### Temporary Write Access

`airnity db connect`/`db browse` get you a **read** session on a database. `airnity db access`
is how you get **write** rights on one, for a bounded time, with a justification that is
recorded.

The two are siblings on purpose, and they answer different questions from different
authorities:

| | `db connect` / `db browse` | `db access` |
| --- | --- | --- |
| Question | "Which instances can I open a session on, and open it" | "May I write to this database for the next few hours" |
| Authority | the `selfservice-database-rw` service for discovery; gcloud IAM for the connection itself | the `selfservice-database-rw` service |
| Credential | your **gcloud** account | your **Keycloak** token (`airnity login`) |
| Lists | every database you can *connect* to, instance and all | write grants and pending requests you currently hold |

A typical sequence uses both: find the database and its `ref` with `db list databases -o
json`, ask for write access with `db access`, then open the session with `db
connect`/`db browse`. When you're already in `db browse`'s browser, press `w` on a database
to request or revoke write access without leaving it — the subcommands below are for
scripting.

`w` opens a request form (duration presets up to the server's 8h maximum, plus a
justification field) when the highlighted database has no access on it yet. If it already
has a grant or a pending request, `w` instead opens a confirmation to revoke it or withdraw
the request. A request that is granted outright offers to connect right away.

```shell
airnity db list databases -o json | jq -r '.databases[] | "\(.ref)\t\(.write)"'
airnity db access grants                    # write access you currently hold
```

Requesting, holding and handing back access:

```shell
# Ask for write access. Both flags matter: the justification is audited. The ref comes
# from 'db list databases -o json' (its "ref" field).
airnity db access request my-cluster/orders --ttl 2h --justification "hotfix INC-4711"

# Give it back early
airnity db access grants                    # find the id
airnity db access revoke <grant-id>

# Withdraw a request that is still waiting
airnity db access cancel <request-id>
```

Some databases require an approver. Those requests queue instead of being granted, and
`w` in `db browse` shows "awaiting approval" until one acts on it — approving or rejecting a
request is done from the selfservice-database-rw web UI, not the CLI.

#### What the CLI does not decide

The service is the authority, and this command reports its answers rather than
second-guessing them:

- **How long** a grant may last is server policy. `--ttl` is sent as you typed it; if it is
  out of bounds the server refuses and the CLI prints its explanation. There is no
  client-side clamp and no hardcoded list of allowed durations.
- **Which databases you see** is a server authorisation decision. `--env` / `--region` /
  `--name` only narrow what is printed.
- **Four-eyes**: you cannot approve your own request. The server enforces that from your
  token.
- A database you can **already** write to permanently is shown as such, and no grant is
  offered on it.

#### Requirements

- Authenticated with Keycloak (`airnity login` or `airnity auth login`). Each subcommand
  runs the login flow automatically when interactive, and errors out when not.
- Network access to the service. Override the endpoint with `AIRNITY_DATABASE_RW_URL`
  (there is no dev/prod switch — the variable *is* the mechanism).

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
# Install the bifrost MCP server and configure Claude Code's global settings.json
# (honors CLAUDE_CONFIG_DIR if set, defaulting to ~/.claude/settings.json)
airnity claude configure

# Toggle MCP servers on/off for the current project
airnity claude mcp manage
```

The `claude` command manages Claude Code configuration: bifrost MCP setup and per-project MCP server permissions (written to `.claude/settings.local.json`). In an interactive terminal, `claude configure` walks through a short questionnaire, starting with your **default provider**:

- **Claude Team subscription** — route through your Claude Team subscription, no per-token billing (requires a Team seat)
- **bifrost** — route through the Airnity bifrost proxy, billed per token via the Google Cloud API

Then the usual `model` (recommended: `opusplan`) and `effortLevel` (recommended: `high`), plus optional toggles (bundled skills, dynamic workflows, artifacts, and a few tool permissions) to reduce Claude Code's context usage.

`configure` also installs a SessionStart hook into your global `settings.json` that injects a short instruction block into every Claude Code session, teaching it to prefer the airnity CLI (`airnity db`, `airnity argo`) over raw cloud tooling. If the `airnity` binary is ever missing, the hook silently does nothing. Your own hooks are never touched.

Regardless of which provider you pick as your default, `configure` always (re)writes `~/.claude/bifrost-settings.json`, a small overlay containing only the bifrost-specific settings. This means bifrost is always one command away, even on a Claude-Team-default machine: `configure`'s summary prints a one-time alias to add to your shell config —

```shell
alias claude-bifrost='claude --settings ~/.claude/bifrost-settings.json'
```

Add it once to `~/.zshrc` or `~/.bashrc` (`configure` tells you which, based on `$SHELL`), then fall back to bifrost for a single session whenever you hit your subscription's usage cap: `claude-bifrost`, or `claude-bifrost --continue` to resume the conversation you were having on your Claude Team subscription. This is a launch-time choice, not a persistent toggle — it never changes your configured default, and there's no separate `airnity` subcommand for it.

Whenever a session is routed through bifrost — whether it's your configured default or a one-off `claude-bifrost` fallback — Claude Code shows a `companyAnnouncements` banner at startup reminding you it's billed per token. This never touches your `statusLine` or any other personal customization: `~/.claude/bifrost-settings.json` only ever describes a bifrost session, so the banner it carries doesn't need to check anything at runtime.

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

### Certificates

```shell
# Show whether the Airnity Root CA is trusted system-wide
airnity certs ca status

# Install the Airnity Root CA into the OS trust store (requires sudo/admin)
airnity certs ca install

# Print your personal TLS material (ca.crt, tls.crt, tls.key) labeled
airnity certs user

# Print a single key's PEM contents (pipe-friendly)
airnity certs user tls.crt | openssl x509 -noout -subject
```

The `certs ca` commands manage trust of the embedded Airnity Root CA, required to access `*.airnity.private` URLs.

The `certs user` command prints your personal TLS certificate and key issued by the IDP backend. With no argument all keys are printed labeled; pass a single key name (`ca.crt`, `tls.crt`, or `tls.key`) to print only its PEM contents to stdout.

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

To back up the files, clean up, import the keys into your keyring and verify that everything works, follow the documentation from the **Back up your keys** section onward:
https://airnity.fibery.io/Knowledge_Management/How_to/Generate-and-manage-your-GPG-keys-153/anchor=Back-up-your-keys--ca470498-b51e-414e-a5f8-1d7f74325129

## Shell Completion

`airnity` supports tab-completion for commands, flags, and dynamic values such as
`db connect proxy --instance <TAB>` (a live, bounded query to selfservice-database-rw).

Completion is opt-in: you load a small script once that tells your shell to ask `airnity`
for suggestions. The script does **not** contain the suggestions themselves — they are
fetched live from the binary on each `<TAB>`, so they stay current.

Pick your shell:

```sh
# zsh (oh-my-zsh) — autoloaded on next shell start
airnity completion zsh > ~/.oh-my-zsh/cache/completions/_airnity
# zsh (plain) — ensure `autoload -Uz compinit; compinit` is in ~/.zshrc, then:
airnity completion zsh > "${fpath[1]}/_airnity"

# bash — requires the bash-completion package
airnity completion bash | sudo tee /etc/bash_completion.d/airnity > /dev/null

# fish
airnity completion fish > ~/.config/fish/completions/airnity.fish

# powershell — add to your $PROFILE
airnity completion powershell | Out-String | Invoke-Expression
```

Restart your shell (`exec zsh` / open a new terminal) afterwards. If completion still
falls back to filenames in zsh, clear the completion cache once: `rm -f ~/.zcompdump* && exec zsh`.

Run `airnity completion <shell> --help` for the details of any shell. Re-run the command
above after upgrading `airnity` if new commands or flags were added.
