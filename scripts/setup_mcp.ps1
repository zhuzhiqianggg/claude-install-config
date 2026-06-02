<#
.SYNOPSIS
    Claude Code MCP 服务器配置脚本
.DESCRIPTION
    交互式注册/管理 MCP 服务器
.EXAMPLE
    .\setup_mcp.ps1
    .\setup_mcp.ps1 -Preset recommended
#>
param(
    [ValidateSet("recommended","full","minimal","custom","")]
    [string]$Preset = "",
    [switch]$List,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$CLAUDE_DIR = "$HOME\.claude"
$MCP_PATH = "$CLAUDE_DIR\mcp.json"

function Write-Step($msg) { Write-Host "`n[STEP] $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "[OK]   $msg" -ForegroundColor Green }
function Write-Info($msg) { Write-Host "[INFO] $msg" -ForegroundColor White }

$MCP_REGISTRY = @{
    "context7" = @{
        command = "npx"
        args = @("-y", "@upstash/context7-mcp")
        desc = "实时文档检索 - 获取最新框架文档，防止幻觉"
    }
    "sequential-thinking" = @{
        command = "npx"
        args = @("-y", "@modelcontextprotocol/server-sequential-thinking")
        desc = "结构化推理 - 复杂问题分步思考"
    }
    "fetch" = @{
        command = "npx"
        args = @("-y", "@modelcontextprotocol/server-fetch")
        desc = "网页抓取 - 获取API文档、Changelog"
    }
    "memory" = @{
        command = "npx"
        args = @("-y", "@modelcontextprotocol/server-memory")
        desc = "持久化记忆 - 跨会话保存关键信息"
    }
    "playwright" = @{
        command = "npx"
        args = @("-y", "@playwright/mcp@latest")
        desc = "浏览器自动化 - E2E测试、页面截图"
    }
    "github" = @{
        command = "npx"
        args = @("-y", "@modelcontextprotocol/server-github")
        desc = "GitHub集成 - PR、Issue、代码搜索"
    }
    "filesystem" = @{
        command = "npx"
        args = @("-y", "@modelcontextprotocol/server-filesystem")
        desc = "文件系统访问 - 扩展目录访问"
    }
    "sqlite" = @{
        command = "npx"
        args = @("-y", "@modelcontextprotocol/server-sqlite")
        desc = "SQLite数据库 - 本地数据查询"
    }
    "brave-search" = @{
        command = "npx"
        args = @("-y", "@modelcontextprotocol/server-brave-search")
        desc = "Brave搜索 - 需要API Key"
    }
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Magenta
Write-Host "  Claude Code MCP 服务器配置工具" -ForegroundColor Magenta
Write-Host "============================================" -ForegroundColor Magenta

# 列出可用 MCP
if ($List) {
    Write-Host "`n可用的 MCP 服务器:" -ForegroundColor Yellow
    $MCP_REGISTRY.GetEnumerator() | Sort-Object Name | ForEach-Object {
        Write-Host "  $($_.Key)" -ForegroundColor Green -NoNewline
        Write-Host " - $($_.Value.desc)"
    }
    return
}

# 读取现有配置
$mcpConfig = @{ mcpServers = @{} }
if (Test-Path $MCP_PATH) {
    $mcpConfig = Get-Content $MCP_PATH -Raw | ConvertFrom-Json -AsHashtable
    Write-Info "检测到现有 MCP 配置 ($($mcpConfig.mcpServers.Count) 个服务器)"
}

# 选择预设
if (-not $Preset) {
    Write-Host "`n选择 MCP 安装方案:" -ForegroundColor Yellow
    Write-Host "  1. 推荐套装 (Context7 + Sequential-Thinking + Fetch + Memory)"
    Write-Host "  2. 完整套装 (推荐 + Playwright + GitHub)"
    Write-Host "  3. 最小安装 (仅 Sequential-Thinking)"
    Write-Host "  4. 自定义选择"
    Write-Host "  5. 跳过"
    Write-Host "  选择 [1-5] : " -NoNewline -ForegroundColor Yellow
    $choice = Read-Host
    $presets = @("recommended","full","minimal","custom","skip")
    $Preset = $presets[([int]$choice - 1)]
}

$selected = @()

switch ($Preset) {
    "recommended" { $selected = @("context7","sequential-thinking","fetch","memory") }
    "full" { $selected = @("context7","sequential-thinking","fetch","memory","playwright","github") }
    "minimal" { $selected = @("sequential-thinking") }
    "custom" {
        Write-Host "`n选择要安装的 MCP (输入编号，逗号分隔):" -ForegroundColor Yellow
        $keys = $MCP_REGISTRY.Keys | Sort-Object
        $i = 1
        foreach ($k in $keys) {
            $installed = $mcpConfig.mcpServers.ContainsKey($k)
            $marker = if ($installed) { " [已安装]" } else { "" }
            Write-Host "  $i. $k - $($MCP_REGISTRY[$k].desc)$marker"
            $i++
        }
        Write-Host "  选择: " -NoNewline -ForegroundColor Yellow
        $input = Read-Host
        $indices = $input -split "," | ForEach-Object { [int]$_ - 1 }
        $sortedKeys = @($keys)
        foreach ($idx in $indices) {
            if ($idx -ge 0 -and $idx -lt $sortedKeys.Count) {
                $selected += $sortedKeys[$idx]
            }
        }
    }
    "skip" { Write-Info "跳过 MCP 配置"; return }
}

# 写入配置
if ($selected.Count -gt 0) {
    foreach ($name in $selected) {
        $info = $MCP_REGISTRY[$name]
        $mcpConfig.mcpServers[$name] = @{
            command = $info.command
            args = $info.args
        }
        Write-Ok "注册: $name - $($info.desc)"
    }

    if (-not $DryRun) {
        @{ mcpServers = $mcpConfig.mcpServers } | ConvertTo-Json -Depth 3 | Set-Content $MCP_PATH -Encoding UTF8
    }
    Write-Step "MCP 配置完成 ($($selected.Count) 个服务器)"
    Write-Info "重启 Claude Code 生效"
    Write-Info "在 Claude Code 中输入 /mcp 查看连接状态"
}
