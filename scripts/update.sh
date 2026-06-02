#!/bin/bash
# =============================================================================
# Claude Code One-Click Update Script (Linux/macOS)
# =============================================================================

set -e

CLAUDE_DIR="$HOME/.claude"
CONFIG_DIR="$HOME/.config"
SUPERPOWERS_DIR="$CONFIG_DIR/superpowers"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

step() { echo -e "\n${CYAN}[STEP] $1${NC}"; }
ok()   { echo -e "${GREEN}[OK]   $1${NC}"; }
warn() { echo -e "${YELLOW}[WARN] $1${NC}"; }
err()  { echo -e "${RED}[ERR]  $1${NC}"; }
info() { echo -e "[INFO] $1"; }

echo -e "\n${MAGENTA}============================================${NC}"
echo -e "${MAGENTA}  Claude Code One-Click Update Tool${NC}"
echo -e "${MAGENTA}============================================${NC}"

# Step 1: Upgrade Claude Code CLI
step "Step 1/4: Upgrade Claude Code CLI"

if command -v claude &> /dev/null; then
    old_ver=$(claude --version 2>/dev/null || echo "unknown")
    info "Current version: $old_ver"
    info "Upgrading..."
    
    # Download install script
    install_script=$(curl -fsSL https://claude.ai/install.sh 2>/dev/null) || true
    
    if [ -n "$install_script" ] && echo "$install_script" | head -1 | grep -q '^#!/'; then
        echo "$install_script" | bash
        new_ver=$(claude --version 2>/dev/null || echo "unknown")
        if [ "$new_ver" != "$old_ver" ]; then
            ok "Upgraded: $old_ver -> $new_ver"
        else
            ok "Already latest: $new_ver"
        fi
    else
        warn "Cannot reach claude.ai (may need proxy)"
        info "Try: curl -fsSL https://claude.ai/install.sh | bash"
        info "Or use npm: npm update -g @anthropic-ai/claude-code"
    fi
else
    warn "Claude Code not installed, run install.sh first"
fi

# Step 2: Update Superpowers
step "Step 2/4: Update Superpowers"

if [ -d "$SUPERPOWERS_DIR" ]; then
    info "Updating Superpowers..."
    cd "$SUPERPOWERS_DIR"
    git pull
    cd - > /dev/null
    ok "Superpowers updated"
else
    warn "Superpowers not installed, run install.sh first"
fi

# Step 3: Check plugins
step "Step 3/4: Check plugins"

plugins_json="$CLAUDE_DIR/plugins.json"
if [ -f "$plugins_json" ]; then
    info "Registered plugins:"
    if command -v jq &> /dev/null; then
        jq -r '.plugins | to_entries[] | "  \(.key) (\(.value.type))"' "$plugins_json"
    else
        cat "$plugins_json"
    fi
else
    warn "plugins.json not found, run install.sh first"
fi

# Step 4: Check MCP servers
step "Step 4/4: Check MCP servers"

mcp_json="$CLAUDE_DIR/mcp.json"
if [ -f "$mcp_json" ]; then
    info "Registered MCP servers:"
    if command -v jq &> /dev/null; then
        jq -r '.mcpServers | keys[] | "  \(.)"' "$mcp_json"
    else
        cat "$mcp_json"
    fi
else
    warn "mcp.json not found, run install.sh first"
fi

# Done
echo -e "\n${MAGENTA}============================================${NC}"
echo -e "${GREEN}  Update complete!${NC}"
echo -e "${MAGENTA}============================================${NC}"
echo ""
info "Restart Claude Code: claude"
