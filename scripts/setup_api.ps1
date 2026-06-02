<#
.SYNOPSIS
    Claude Code API 配置脚本
.DESCRIPTION
    交互式配置 API 提供商和密钥
.EXAMPLE
    .\setup_api.ps1
    .\setup_api.ps1 -Provider volcengine
#>
param(
    [ValidateSet("volcengine","anthropic","openrouter","")]
    [string]$Provider = "",
    [string]$ApiKey = "",
    [string]$Model = ""
)

$ErrorActionPreference = "Stop"
$CLAUDE_DIR = "$HOME\.claude"
$SETTINGS_PATH = "$CLAUDE_DIR\settings.json"

function Write-Step($msg) { Write-Host "`n[STEP] $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "[OK]   $msg" -ForegroundColor Green }
function Write-Info($msg) { Write-Host "[INFO] $msg" -ForegroundColor White }

function Get-Input($prompt, $default = "") {
    if ($default) { $prompt += " [$default]" }
    Write-Host "$prompt : " -NoNewline -ForegroundColor Yellow
    $input = Read-Host
    if (-not $input -and $default) { return $default }
    return $input
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Magenta
Write-Host "  Claude Code API 配置工具" -ForegroundColor Magenta
Write-Host "============================================" -ForegroundColor Magenta

# 读取现有配置
$settings = @{}
if (Test-Path $SETTINGS_PATH) {
    $settings = Get-Content $SETTINGS_PATH -Raw | ConvertFrom-Json -AsHashtable
    Write-Info "检测到现有配置"
    if ($settings.env.ANTHROPIC_BASE_URL) { Write-Info "  Base URL: $($settings.env.ANTHROPIC_BASE_URL)" }
    if ($settings.env.ANTHROPIC_MODEL) { Write-Info "  Model: $($settings.env.ANTHROPIC_MODEL)" }
    if ($settings.env.ANTHROPIC_AUTH_TOKEN) { Write-Info "  API Key: $($settings.env.ANTHROPIC_AUTH_TOKEN.Substring(0,[Math]::Min(15,$settings.env.ANTHROPIC_AUTH_TOKEN.Length)))..." }
}

# 选择提供商
if (-not $Provider) {
    Write-Host "`n选择 API 提供商:" -ForegroundColor Yellow
    Write-Host "  1. 火山方舟 Coding Plan (推荐国内用户)"
    Write-Host "  2. Anthropic 官方 API"
    Write-Host "  3. OpenRouter"
    Write-Host "  4. 自定义 Base URL"
    Write-Host "  选择 [1-4] : " -NoNewline -ForegroundColor Yellow
    $choice = Read-Host
    $providers = @("volcengine","anthropic","openrouter","custom")
    $Provider = $providers[([int]$choice - 1)]
}

$baseUrl = ""
$authToken = $ApiKey
$model = $Model

switch ($Provider) {
    "volcengine" {
        $baseUrl = "https://ark.cn-beijing.volces.com/api/coding"
        if (-not $authToken) { $authToken = Get-Input "输入火山方舟 API Key (ark-...)" }
        if (-not $model) {
            Write-Host "`n选择模型:" -ForegroundColor Yellow
            Write-Host "  1. doubao-seed-code-preview-latest (豆包编程，推荐)"
            Write-Host "  2. ark-code-latest (DeepSeek V3.2)"
            Write-Host "  3. glm-5.1 (GLM)"
            Write-Host "  4. doubao-seed-2.0-pro (豆包2.0 Pro)"
            Write-Host "  5. doubao-seed-2.0-lite (豆包2.0 Lite，轻量快速)"
            Write-Host "  选择 [1-5] : " -NoNewline -ForegroundColor Yellow
            $mChoice = Read-Host
            $models = @("doubao-seed-code-preview-latest","ark-code-latest","glm-5.1","doubao-seed-2.0-pro","doubao-seed-2.0-lite")
            $model = $models[([int]$mChoice - 1)]
        }
    }
    "anthropic" {
        $baseUrl = ""
        if (-not $authToken) { $authToken = Get-Input "输入 Anthropic API Key (sk-ant-...)" }
        if (-not $model) { $model = "claude-sonnet-4-20250514" }
    }
    "openrouter" {
        $baseUrl = "https://openrouter.ai/api/v1"
        if (-not $authToken) { $authToken = Get-Input "输入 OpenRouter API Key" }
        if (-not $model) { $model = "anthropic/claude-sonnet-4-20250514" }
    }
    "custom" {
        $baseUrl = Get-Input "输入自定义 Base URL"
        if (-not $authToken) { $authToken = Get-Input "输入 API Key"
        if (-not $model) { $model = Get-Input "输入模型名称" }
    }
}

# 写入配置
if ($authToken) {
    if (-not $settings.env) { $settings.env = @{} }
    $settings.env.ANTHROPIC_AUTH_TOKEN = $authToken
    if ($baseUrl) { $settings.env.ANTHROPIC_BASE_URL = $baseUrl }
    elseif ($settings.env.ContainsKey("ANTHROPIC_BASE_URL")) { $settings.env.Remove("ANTHROPIC_BASE_URL") }
    if ($model) { $settings.env.ANTHROPIC_MODEL = $model }
    $settings.env.API_TIMEOUT_MS = "600000"
    $settings.env.CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1"

    $settings | ConvertTo-Json -Depth 5 | Set-Content $SETTINGS_PATH -Encoding UTF8
    Write-Step "配置已写入"
    Write-Ok "Provider: $Provider"
    Write-Ok "Model: $model"
    if ($baseUrl) { Write-Ok "Base URL: $baseUrl" }
    Write-Ok "API Key: $($authToken.Substring(0,[Math]::Min(15,$authToken.Length)))..."
    Write-Info ""
    Write-Info "重启 Claude Code 生效: claude"
    Write-Info "验证连接: 在 Claude Code 中输入 /status"
} else {
    Write-Host "未输入 API Key，配置未更改" -ForegroundColor Red
}
