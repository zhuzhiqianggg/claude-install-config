#!/bin/bash
# =============================================================================
# Claude Code One-Click Install Script (Linux/macOS)
# =============================================================================

set -e

CLAUDE_DIR="$HOME/.claude"
CONFIG_DIR="$HOME/.config"
SUPERPOWERS_DIR="$CONFIG_DIR/superpowers"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

step()   { echo -e "\n${CYAN}[STEP] $1${NC}"; }
ok()     { echo -e "${GREEN}[OK]   $1${NC}"; }
warn()   { echo -e "${YELLOW}[WARN] $1${NC}"; }
err()    { echo -e "${RED}[ERR]  $1${NC}"; }
info()   { echo -e "[INFO] $1"; }

get_input() {
    local prompt="$1"
    local default="$2"
    if [ -n "$default" ]; then
        prompt="$prompt [$default]"
    fi
    echo -ne "${YELLOW}$prompt : ${NC}"
    read -r input
    if [ -z "$input" ] && [ -n "$default" ]; then
        echo "$default"
    else
        echo "$input"
    fi
}

get_choice() {
    local prompt="$1"
    shift
    local choices=("$@")
    local default=0
    
    echo -e "\n${YELLOW}$prompt${NC}"
    for i in "${!choices[@]}"; do
        if [ "$i" -eq "$default" ]; then
            echo "  > $((i+1)). ${choices[$i]}"
        else
            echo "    $((i+1)). ${choices[$i]}"
        fi
    done
    echo -ne "${YELLOW}  Select [1-${#choices[@]}] : ${NC}"
    read -r input
    if [ -z "$input" ]; then
        echo "$default"
    else
        echo $((input - 1))
    fi
}

echo -e "\n${MAGENTA}============================================${NC}"
echo -e "${MAGENTA}  Claude Code One-Click Install Tool${NC}"
echo -e "${MAGENTA}  Linux/macOS Bash Edition${NC}"
echo -e "${MAGENTA}============================================${NC}"

# Step 1: Check dependencies
step "Step 1/11: Check dependencies"

missing=()
if ! command -v node &> /dev/null; then missing+=("Node.js 18+"); fi
if ! command -v git &> /dev/null; then missing+=("Git"); fi

if [ ${#missing[@]} -gt 0 ]; then
    err "Missing dependencies: ${missing[*]}"
    info "Please install: https://nodejs.org / https://git-scm.com"
    exit 1
fi

node_ver=$(node --version)
git_ver=$(git --version)
ok "Node.js $node_ver"
ok "Git $git_ver"

# Step 2: Install Claude Code CLI
step "Step 2/11: Install Claude Code CLI"

install_claude() {
    local script
    script=$(curl -fsSL https://claude.ai/install.sh 2>/dev/null) || true
    if [ -n "$script" ] && echo "$script" | head -1 | grep -q '^#!/'; then
        echo "$script" | bash
        return 0
    else
        return 1
    fi
}

if command -v claude &> /dev/null; then
    ver=$(claude --version 2>/dev/null || echo "unknown")
    ok "Claude Code already installed: $ver"
    ok "Skipping upgrade (use update.sh to upgrade)"
else
    info "Installing Claude Code..."
    if install_claude; then
        ok "Claude Code installed"
    else
        warn "Cannot reach claude.ai (may need proxy)"
        info "Try: curl -fsSL https://claude.ai/install.sh | bash"
        info "Or use npm: npm install -g @anthropic-ai/claude-code"
    fi
fi

# Step 3: Configure environment
step "Step 3/11: Configure environment"

mkdir -p "$CLAUDE_DIR"
mkdir -p "$CONFIG_DIR"
ok "Config directory: $CLAUDE_DIR"

# Step 4: Fix Git GitHub connection
step "Step 4/11: Fix Git GitHub connection"

git_ok=false
if git ls-remote https://github.com/anthropics/claude-code.git HEAD &>/dev/null; then
    git_ok=true
    ok "Git GitHub connection OK"
else
    warn "GitHub connection failed, attempting fix..."
    
    # Try SSH
    if ssh -T git@github.com 2>&1 | grep -q "authenticated"; then
        git config --global url."git@github.com:".insteadOf "https://github.com/"
        git config --global --unset http.proxy 2>/dev/null || true
        git config --global --unset https.proxy 2>/dev/null || true
        ok "Git configured to use SSH"
        git_ok=true
    fi
    
    # Try proxy
    if [ "$git_ok" = false ]; then
        for port in 1080 7890 10808; do
            if nc -z 127.0.0.1 $port 2>/dev/null; then
                git config --global http.proxy "socks5h://127.0.0.1:$port"
                git config --global https.proxy "socks5h://127.0.0.1:$port"
                if git ls-remote https://github.com/anthropics/claude-code.git HEAD &>/dev/null; then
                    ok "Git configured to use proxy 127.0.0.1:$port"
                    git_ok=true
                    break
                fi
            fi
        done
    fi
    
    if [ "$git_ok" = false ]; then
        warn "Git auto-fix failed"
    fi
fi

# Step 5: Configure API
step "Step 5/11: Configure API"

if [ -f "$CLAUDE_DIR/settings.json" ]; then
    ok "settings.json already exists, skipping"
else
    info "Skipping API config (run setup_api.sh to configure)"
    info "Or edit ~/.claude/settings.json manually"
fi

# Step 6: Generate CLAUDE.md
step "Step 6/11: Generate CLAUDE.md"

claude_md_path="$CLAUDE_DIR/CLAUDE.md"
if [ ! -f "$claude_md_path" ]; then
    template_path="$PROJECT_DIR/config/CLAUDE.md"
    if [ -f "$template_path" ]; then
        cp "$template_path" "$claude_md_path"
        ok "CLAUDE.md copied from template"
    else
        warn "CLAUDE.md template not found"
    fi
else
    ok "CLAUDE.md already exists"
fi

# Step 7: Install Superpowers Skills (from GitHub)
step "Step 7/11: Install Superpowers Skills"

if [ -d "$SUPERPOWERS_DIR" ]; then
    info "Updating Superpowers..."
    cd "$SUPERPOWERS_DIR"
    git pull
    cd - > /dev/null
    ok "Superpowers updated"
else
    info "Cloning Superpowers from GitHub..."
    git clone https://github.com/obra/superpowers.git "$SUPERPOWERS_DIR"
    ok "Superpowers installed to: $SUPERPOWERS_DIR"
fi

cat > "$CLAUDE_DIR/plugins.json" << EOF
{
    "plugins": {
        "superpowers": {
            "type": "local",
            "path": "$SUPERPOWERS_DIR"
        }
    }
}
EOF
ok "plugins.json written"

# Step 8: Install additional plugins
step "Step 8/11: Install additional plugins"

plugins_conf_path="$PROJECT_DIR/config/plugins.conf"
if [ -f "$plugins_conf_path" ] && command -v claude &> /dev/null; then
    plugins=$(grep -v '^\s*#' "$plugins_conf_path" | grep -v '^\s*$' | sed 's/#.*//' | tr -d ' ' | grep -v '^superpowers@')
    plugin_count=$(echo "$plugins" | grep -c .)
    info "Installing $plugin_count plugins..."
    installed=0
    while IFS= read -r plugin; do
        if [ -n "$plugin" ]; then
            info "  $plugin ..."
            claude plugin install "$plugin" 2>/dev/null && ((installed++)) || true
        fi
    done <<< "$plugins"
    ok "$installed plugins installed"
else
    warn "Skipping plugins"
fi

# Step 9: Register MCP servers
step "Step 9/11: Register MCP servers"

if [ -f "$CLAUDE_DIR/mcp.json" ]; then
    ok "mcp.json already exists, skipping"
else
    info "Installing recommended MCP servers..."
    cat > "$CLAUDE_DIR/mcp.json" << 'EOF'
{
    "mcpServers": {
        "context7": { "command": "npx", "args": ["-y", "@upstash/context7-mcp"] },
        "sequential-thinking": { "command": "npx", "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"] },
        "fetch": { "command": "npx", "args": ["-y", "@modelcontextprotocol/server-fetch"] },
        "memory": { "command": "npx", "args": ["-y", "@modelcontextprotocol/server-memory"] }
    }
}
EOF
    ok "mcp.json written (4 servers)"
fi

# Step 10: Verify installation
step "Step 10/11: Verify installation"

all_ok=true

if command -v claude &> /dev/null; then ok "Claude Code CLI"; else warn "Claude Code CLI - not ready"; all_ok=false; fi
if [ -f "$CLAUDE_DIR/settings.json" ]; then ok "settings.json"; else warn "settings.json - not ready"; all_ok=false; fi
if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then ok "CLAUDE.md"; else warn "CLAUDE.md - not ready"; all_ok=false; fi
if [ -d "$SUPERPOWERS_DIR" ]; then ok "Superpowers"; else warn "Superpowers - not ready"; all_ok=false; fi
if [ -f "$CLAUDE_DIR/plugins.json" ]; then ok "plugins.json"; else warn "plugins.json - not ready"; all_ok=false; fi
if [ -f "$CLAUDE_DIR/mcp.json" ]; then ok "mcp.json"; else warn "mcp.json - not ready"; all_ok=false; fi

# Step 11: Complete
step "Step 11/11: Complete"

echo -e "\n${MAGENTA}============================================${NC}"
if $all_ok; then
    echo -e "${GREEN}  Installation complete!${NC}"
else
    echo -e "${YELLOW}  Installation complete (some items need attention)${NC}"
fi
echo -e "${MAGENTA}============================================${NC}"

echo ""
info "Next steps:"
info "  1. Run 'claude' to start"
info "  2. Enter /status to verify"
info "  3. Enter /find-skills to see Skills"
echo ""
info "Update:  cd $PROJECT_DIR ; ./scripts/update.sh"
info "API:     ./scripts/setup_api.sh"
info "MCP:     ./scripts/setup_mcp.sh"
