#!/bin/bash
# =============================================================================
# Claude Code 一键更新脚本 (Linux/macOS)
# =============================================================================

set -e

CLAUDE_DIR="$HOME/.claude"
CONFIG_DIR="$HOME/.config"
SUPERPOWERS_DIR="$CONFIG_DIR/superpowers"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

step() { echo -e "\n${CYAN}[STEP] $1${NC}"; }
ok()   { echo -e "${GREEN}[OK]   $1${NC}"; }
warn() { echo -e "${YELLOW}[WARN] $1${NC}"; }
info() { echo -e "[INFO] $1"; }

echo -e "\n${MAGENTA}============================================${NC}"
echo -e "${MAGENTA}  Claude Code 一键更新工具${NC}"
echo -e "${MAGENTA}============================================${NC}"

# Step 1: 升级 Claude Code CLI
step "Step 1/4: 升级 Claude Code CLI"

if command -v claude &> /dev/null; then
    old_ver=$(claude --version 2>/dev/null || echo "unknown")
    info "当前版本: $old_ver"
    info "正在升级..."
    curl -fsSL https://claude.ai/install.sh | sh
    new_ver=$(claude --version 2>/dev/null || echo "unknown")
    if [ "$new_ver" != "$old_ver" ]; then
        ok "已升级: $old_ver -> $new_ver"
    else
        ok "已是最新版: $new_ver"
    fi
else
    warn "Claude Code 未安装，运行 install.sh"
fi

# Step 2: 更新 Superpowers
step "Step 2/4: 更新 Superpowers"

if [ -d "$SUPERPOWERS_DIR" ]; then
    info "正在更新 Superpowers..."
    cd "$SUPERPOWERS_DIR"
    git pull
    cd - > /dev/null
    ok "Superpowers 已更新"
else
    warn "Superpowers 未安装，运行 install.sh"
fi

# Step 3: 检查插件状态
step "Step 3/4: 检查插件状态"

plugins_json="$CLAUDE_DIR/plugins.json"
if [ -f "$plugins_json" ]; then
    info "已注册插件:"
    if command -v jq &> /dev/null; then
        jq -r '.plugins | to_entries[] | "  \(.key) (\(.value.type))"' "$plugins_json"
    else
        cat "$plugins_json"
    fi
else
    warn "plugins.json 不存在，运行 install.sh 创建"
fi

# Step 4: 检查 MCP 服务器
step "Step 4/4: 检查 MCP 服务器"

mcp_json="$CLAUDE_DIR/mcp.json"
if [ -f "$mcp_json" ]; then
    info "已注册 MCP 服务器:"
    if command -v jq &> /dev/null; then
        jq -r '.mcpServers | keys[] | "  \(.)"' "$mcp_json"
    else
        cat "$mcp_json"
    fi
else
    warn "mcp.json 不存在，运行 install.sh 创建"
fi

# 完成
echo -e "\n${MAGENTA}============================================${NC}"
echo -e "${GREEN}  更新完成!${NC}"
echo -e "${MAGENTA}============================================${NC}"
echo ""
info "重启 Claude Code 使更新生效: claude"
