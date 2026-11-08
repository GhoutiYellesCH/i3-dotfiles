#!/usr/bin/env bash

# Automated Dotfiles Sync Script
# Syncs active desktop configs to ~/workspace/i3-dotfiles and pushes to GitHub

REPO_DIR="$HOME/workspace/i3-dotfiles"
LOG_FILE="$HOME/.cache/dotfiles_sync.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

# Ensure repo directory exists
if [ ! -d "$REPO_DIR/.git" ]; then
    log "Error: $REPO_DIR is not a git repository."
    exit 1
fi

log "Starting dotfiles sync check..."

# 1. Sync active configuration directories into the repo
rsync -a --delete --exclude '.cache' --exclude 'Wallpapers' "$HOME/.config/i3/" "$REPO_DIR/config/i3/" 2>> "$LOG_FILE"
rsync -a --delete "$HOME/.config/polybar/" "$REPO_DIR/config/polybar/" 2>> "$LOG_FILE"
rsync -a "$HOME/.config/rofi/" "$REPO_DIR/config/rofi/" 2>> "$LOG_FILE"
rsync -a "$HOME/.config/dunst/" "$REPO_DIR/config/dunst/" 2>> "$LOG_FILE"
rsync -a "$HOME/.config/kitty/" "$REPO_DIR/config/kitty/" 2>> "$LOG_FILE"
rsync -a "$HOME/.config/fastfetch/" "$REPO_DIR/config/fastfetch/" 2>> "$LOG_FILE"
[ -f "$HOME/.config/greenclip.toml" ] && cp -a "$HOME/.config/greenclip.toml" "$REPO_DIR/config/"

# 2. Check for changes in git repo
cd "$REPO_DIR" || exit 1

if [ -z "$(git status --porcelain)" ]; then
    log "No changes detected. Repository is already up to date."
    exit 0
fi

log "Changes detected in dotfiles. Preparing commit..."

# 3. Check network connectivity to GitHub
if ! ping -c 1 -W 3 github.com >/dev/null 2>&1; then
    log "No internet connection to github.com. Will retry next run."
    exit 0
fi

# 4. Commit and push changes
git add . >> "$LOG_FILE" 2>&1
commit_msg="chore: auto-sync dotfiles update ($(date '+%Y-%m-%d %H:%M'))"
git commit -m "$commit_msg" >> "$LOG_FILE" 2>&1

if git push origin main >> "$LOG_FILE" 2>&1; then
    log "Successfully pushed updates to GitHub: $commit_msg"
    # Send desktop notification if desktop session is active
    if [ -n "$DISPLAY" ]; then
        notify-send "Dotfiles Auto-Sync" "Pushed latest configuration changes to GitHub" -i git
    fi
else
    log "Error: Failed to push updates to GitHub."
fi
