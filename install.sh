#!/bin/sh
# Install the latest airnity CLI on macOS or Linux.
#
#   curl -fsSL https://raw.githubusercontent.com/airnity/airnity-cli-releases/main/install.sh | sh
#
set -eu

BASE="${BASE:-https://github.com/airnity/airnity-cli-releases/releases/latest/download}"
DEST="$HOME/.local/bin"

err() {
	printf 'error: %s\n' "$1" >&2
	exit 1
}

command -v curl >/dev/null 2>&1 || err "curl is required but not found"

case "$(uname -s)" in
Darwin) OS=darwin ;;
Linux) OS=linux ;;
*) err "unsupported OS: $(uname -s) (only darwin and linux are supported)" ;;
esac

case "$(uname -m)" in
x86_64 | amd64) ARCH=amd64 ;;
arm64 | aarch64) ARCH=arm64 ;;
*) err "unsupported architecture: $(uname -m)" ;;
esac

if [ "$OS" = linux ] && [ "$ARCH" = arm64 ]; then
	err "no linux/arm64 release is published; build from source instead"
fi

ASSET="airnity-${OS}-${ARCH}"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

printf 'Downloading %s...\n' "$ASSET"
curl -fsSL "$BASE/$ASSET" -o "$TMP/airnity" || err "download failed: $BASE/$ASSET"

# Verify checksum when a sha256 tool is available. The checksums.txt file lists
# versioned names (airnity_X.Y.Z_os_arch), so match the line by its _os_arch suffix.
if command -v sha256sum >/dev/null 2>&1; then
	SHA_CMD="sha256sum"
elif command -v shasum >/dev/null 2>&1; then
	SHA_CMD="shasum -a 256"
else
	SHA_CMD=""
fi

if [ -n "$SHA_CMD" ]; then
	if curl -fsSL "$BASE/checksums.txt" -o "$TMP/checksums.txt" 2>/dev/null; then
		EXPECTED="$(grep "_${OS}_${ARCH}\$" "$TMP/checksums.txt" | awk '{print $1}')"
		if [ -n "$EXPECTED" ]; then
			ACTUAL="$($SHA_CMD "$TMP/airnity" | awk '{print $1}')"
			[ "$EXPECTED" = "$ACTUAL" ] || err "checksum mismatch (expected $EXPECTED, got $ACTUAL)"
			printf 'Checksum verified.\n'
		else
			printf 'warning: no checksum entry for %s_%s; skipping verification\n' "$OS" "$ARCH" >&2
		fi
	else
		printf 'warning: could not fetch checksums.txt; skipping verification\n' >&2
	fi
else
	printf 'warning: no sha256 tool found; skipping checksum verification\n' >&2
fi

mkdir -p "$DEST"
chmod +x "$TMP/airnity"
mv "$TMP/airnity" "$DEST/airnity"

printf 'Installed airnity to %s\n' "$DEST/airnity"

case ":$PATH:" in
*":$DEST:"*) ;;
*)
	# Pick the rc file for the user's login shell so we can give an exact command.
	SHELL_NAME="$(basename "${SHELL:-}")"
	case "$SHELL_NAME" in
	zsh) RC="$HOME/.zshrc" ;;
	bash)
		# macOS bash reads .bash_profile for login shells; Linux uses .bashrc.
		if [ "$OS" = darwin ]; then RC="$HOME/.bash_profile"; else RC="$HOME/.bashrc"; fi
		;;
	fish) RC="$HOME/.config/fish/config.fish" ;;
	*) RC="" ;;
	esac

	printf '\nwarning: %s is not in your PATH.\n' "$DEST" >&2
	if [ "$SHELL_NAME" = fish ]; then
		printf 'Add it by running:\n  fish_add_path %s\n' "$DEST" >&2
	elif [ -n "$RC" ]; then
		printf 'Add it by running:\n  echo '\''export PATH="%s:$PATH"'\'' >> %s\nThen restart your shell or run: source %s\n' "$DEST" "$RC" "$RC" >&2
	else
		printf 'Add this line to your shell rc file:\n  export PATH="%s:$PATH"\n' "$DEST" >&2
	fi
	;;
esac

"$DEST/airnity" version
