<#
.SYNOPSIS
    Claude Code 一键更新脚本
.DESCRIPTION
    升级 Claude Code CLI + 同步配置文件 + 更新插件
#>
param(
    [switch]$SkipCLI,
    [switch]$SkipConfig,
    [switch]$SkipPlugins,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$CLAUDE_DIR = "$HOME\.claude"
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_DIR = Split-Path -Parent $SCRIPT_DIR

function Write-Step($msg)   { Write-Host "`n[STEP] $msg" -ForegroundColor Cyan }
function Write-Ok($msg)     { Write-Host "[OK]   $msg" -ForegroundColor Green }
function Write-Warn($msg)   { Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Info($msg)   { Write-Host "[INFO] $msg" -ForegroundColor White }

Write-Host ""
Write-Host "============================================" -ForegroundColor Magenta
Write-Host "  Claude Code 一键更新工具" -ForegroundColor Magenta
Write-Host "============================================" -ForegroundColor Magenta

# Step 1: 升级 Claude Code CLI
Write-Step "Step 1/4: 升级 Claude Code CLI"

if ($SkipCLI) {
    Write-Info "跳过 CLI 升级"
} else {
    try {
        $oldVer = (claude --version 2>$null)
        Write-Info "当前版本: $oldVer"
        Write-Info "正在升级..."
        if (-not $DryRun) {
            irm https://claude.ai/install.ps1 | iex
        }
        $newVer = (claude --version 2>$null)
        if ($newVer -ne $oldVer) {
            Write-Ok "已升级: $oldVer -> $newVer"
        } else {
            Write-Ok "已是最新版: $newVer"
        }
    } catch {
        Write-Warn "升级失败: $_"
    }
}

# Step 2: 同步配置文件
Write-Step "Step 2/4: 同步配置文件"

if ($SkipConfig) {
    Write-Info "跳过配置同步"
} else {
    $configDir = "$PROJECT_DIR\config"
    if (Test-Path $configDir) {
        $files = @("CLAUDE.md")
        foreach ($f in $files) {
            $src = "$configDir\$f"
            $dst = "$CLAUDE_DIR\$f"
            if (Test-Path $src) {
                if (-not (Test-Path $dst)) {
                    if (-not $DryRun) { Copy-Item $src $dst -Force }
                    Write-Ok "新建: $f"
                } else {
                    $srcHash = (Get-FileHash $src -Algorithm SHA256).Hash
                    $dstHash = (Get-FileHash $dst -Algorithm SHA256).Hash
                    if ($srcHash -ne $dstHash) {
                        Write-Warn "$f 有更新，但保留本地版本（避免覆盖自定义配置）"
                        Write-Info "  如需更新，手动: Copy-Item '$src' '$dst' -Force"
                    } else {
                        Write-Ok "$f 已是最新"
                    }
                }
            }
        }
    } else {
        Write-Warn "config/ 目录不存在，跳过"
    }
}

# Step 3: 更新插件
Write-Step "Step 3/4: 检查插件状态"

if ($SkipPlugins) {
    Write-Info "跳过插件检查"
} else {
    $pluginsJson = "$CLAUDE_DIR\plugins.json"
    if (Test-Path $pluginsJson) {
        $plugins = Get-Content $pluginsJson -Raw | ConvertFrom-Json
        Write-Info "已注册插件:"
        $plugins.plugins.PSObject.Properties | ForEach-Object {
            Write-Ok "  $($_.Name) ($($_.Value.type): $($_.Value.owner)/$($_.Value.repo))"
        }
        Write-Info "在 Claude Code 中执行 /plugin install superpowers@superpowers-marketplace 更新"
    } else {
        Write-Warn "plugins.json 不存在，运行 install.ps1 创建"
    }
}

# Step 4: 检查 MCP 服务器
Write-Step "Step 4/4: 检查 MCP 服务器"

$mcpJson = "$CLAUDE_DIR\mcp.json"
if (Test-Path $mcpJson) {
    $mcp = Get-Content $mcpJson -Raw | ConvertFrom-Json
    Write-Info "已注册 MCP 服务器:"
    $mcp.mcpServers.PSObject.Properties | ForEach-Object {
        Write-Ok "  $($_.Name)"
    }
} else {
    Write-Warn "mcp.json 不存在，运行 install.ps1 创建"
}

# 完成
Write-Host ""
Write-Host "============================================" -ForegroundColor Magenta
Write-Host "  更新完成!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Magenta
Write-Host ""
Write-Info "重启 Claude Code 使更新生效: claude"
