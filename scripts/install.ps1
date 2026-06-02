<#
.SYNOPSIS
    Claude Code One-Click Install Script (Windows)
.DESCRIPTION
    Install Claude Code CLI, fix Git, install plugins, configure API, Superpowers, MCP
.EXAMPLE
    .\install.ps1
    .\install.ps1 -SkipInstall -SkipAPI
#>
param(
    [switch]$SkipInstall,
    [switch]$SkipGitFix,
    [switch]$SkipAPI,
    [switch]$SkipSuperpowers,
    [switch]$SkipPlugins,
    [switch]$SkipMCP,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$CLAUDE_DIR = "$HOME\.claude"
$CONFIG_DIR = "$HOME\.config"
$SUPERPOWERS_DIR = "$CONFIG_DIR\superpowers"
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_DIR = Split-Path -Parent $SCRIPT_DIR

function Write-Step($msg)   { Write-Host "`n[STEP] $msg" -ForegroundColor Cyan }
function Write-Ok($msg)     { Write-Host "[OK]   $msg" -ForegroundColor Green }
function Write-Warn($msg)   { Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err($msg)    { Write-Host "[ERR]  $msg" -ForegroundColor Red }
function Write-Info($msg)   { Write-Host "[INFO] $msg" -ForegroundColor White }

function Test-Command($cmd) {
    try { Get-Command $cmd -ErrorAction Stop | Out-Null; return $true }
    catch { return $false }
}

function Get-UserInput($prompt, $default = "") {
    if ($default) { $prompt += " [$default]" }
    Write-Host "$prompt : " -NoNewline -ForegroundColor Yellow
    $input = Read-Host
    if (-not $input -and $default) { return $default }
    return $input
}

function Get-UserChoice($prompt, [string[]]$choices, $default = 0) {
    Write-Host "`n$prompt" -ForegroundColor Yellow
    for ($i = 0; $i -lt $choices.Count; $i++) {
        $marker = if ($i -eq $default) { ">" } else { " " }
        Write-Host "  $marker $($i+1). $($choices[$i])" -ForegroundColor White
    }
    Write-Host "  Select [1-$($choices.Count)] : " -NoNewline -ForegroundColor Yellow
    $input = Read-Host
    if (-not $input) { return $default }
    $idx = [int]$input - 1
    if ($idx -ge 0 -and $idx -lt $choices.Count) { return $idx }
    return $default
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Magenta
Write-Host "  Claude Code One-Click Install Tool" -ForegroundColor Magenta
Write-Host "  Windows PowerShell Edition" -ForegroundColor Magenta
Write-Host "============================================" -ForegroundColor Magenta

# Step 1: Check dependencies
Write-Step "Step 1/11: Check dependencies"

$missing = @()
if (-not (Test-Command "node")) { $missing += "Node.js 18+" }
if (-not (Test-Command "git"))  { $missing += "Git" }

if ($missing.Count -gt 0) {
    Write-Err "Missing dependencies: $($missing -join ', ')"
    Write-Info "Please install: https://nodejs.org / https://git-scm.com"
    exit 1
}

$nodeVer = (node --version)
$gitVer = (git --version)
Write-Ok "Node.js $nodeVer"
Write-Ok "Git $gitVer"

$gitBashPath = ""
$possiblePaths = @(
    "C:\Program Files\Git\bin\bash.exe",
    "C:\Program Files (x86)\Git\bin\bash.exe",
    "$env:ProgramFiles\Git\bin\bash.exe"
)
foreach ($p in $possiblePaths) {
    if (Test-Path $p) { $gitBashPath = $p; break }
}
if ($gitBashPath) {
    Write-Ok "Git Bash: $gitBashPath"
} else {
    Write-Warn "Git Bash not found"
}

# Step 2: Install Claude Code CLI
Write-Step "Step 2/11: Install Claude Code CLI"

if ($SkipInstall) {
    Write-Info "Skipping install (-SkipInstall)"
} elseif (Test-Command "claude") {
    $ver = (claude --version 2>$null)
    Write-Ok "Claude Code already installed: $ver"
    $choice = Get-UserChoice "Upgrade to latest version?" @("Skip", "Upgrade")
    if ($choice -eq 1) {
        Write-Info "Upgrading..."
        if (-not $DryRun) {
            irm https://claude.ai/install.ps1 | iex
        }
    }
} else {
    Write-Info "Installing Claude Code..."
    if (-not $DryRun) {
        $policy = Get-ExecutionPolicy -Scope CurrentUser
        if ($policy -eq "Restricted" -or $policy -eq "AllSigned") {
            Write-Info "Adjusting execution policy..."
            Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        }
        irm https://claude.ai/install.ps1 | iex
    }
    Write-Ok "Claude Code installed"
}

# Step 3: Configure Windows environment
Write-Step "Step 3/11: Configure Windows environment"

if ($gitBashPath -and -not $DryRun) {
    [System.Environment]::SetEnvironmentVariable("CLAUDE_CODE_GIT_BASH_PATH", $gitBashPath, "User")
    Write-Ok "CLAUDE_CODE_GIT_BASH_PATH = $gitBashPath"
}

New-Item -ItemType Directory -Path $CLAUDE_DIR -Force | Out-Null
New-Item -ItemType Directory -Path $CONFIG_DIR -Force | Out-Null
Write-Ok "Config directory: $CLAUDE_DIR"

# Step 4: Fix Git GitHub connection
Write-Step "Step 4/11: Fix Git GitHub connection"

if ($SkipGitFix) {
    Write-Info "Skipping Git fix (-SkipGitFix)"
} else {
    $gitOk = $false
    try {
        & git ls-remote https://github.com/anthropics/claude-code.git HEAD 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) { $gitOk = $true }
    } catch {}

    if ($gitOk) {
        Write-Ok "Git GitHub connection OK"
    } else {
        Write-Warn "GitHub connection failed, attempting fix..."
        
        # Try SSH
        try {
            $sshResult = & ssh -T git@github.com 2>&1
            if ($sshResult -match "authenticated") {
                & git config --global url."git@github.com:".insteadOf "https://github.com/"
                & git config --global --unset http.proxy 2>$null
                & git config --global --unset https.proxy 2>$null
                Write-Ok "Git configured to use SSH"
                $gitOk = $true
            }
        } catch {}

        # Try proxy
        if (-not $gitOk) {
            $ports = @(1080, 7890, 10808)
            foreach ($port in $ports) {
                try {
                    $conn = Test-NetConnection -ComputerName 127.0.0.1 -Port $port -WarningAction SilentlyContinue -InformationLevel Quiet
                    if ($conn) {
                        & git config --global http.proxy "socks5h://127.0.0.1:$port"
                        & git config --global https.proxy "socks5h://127.0.0.1:$port"
                        & git ls-remote https://github.com/anthropics/claude-code.git HEAD 2>&1 | Out-Null
                        if ($LASTEXITCODE -eq 0) {
                            Write-Ok "Git configured to use proxy 127.0.0.1:$port"
                            $gitOk = $true
                            break
                        }
                    }
                } catch {}
            }
        }

        if (-not $gitOk) {
            Write-Warn "Git auto-fix failed, run .\scripts\fix-git.ps1 manually"
        }
    }
}

# Step 5: Configure API
Write-Step "Step 5/11: Configure API"

if ($SkipAPI) {
    Write-Info "Skipping API config (-SkipAPI)"
} else {
    $apiChoice = Get-UserChoice "Select API provider:" @(
        "Volcengine Coding Plan (recommended for China)",
        "Anthropic Official API",
        "OpenRouter",
        "Skip (configure manually later)"
    )

    $baseUrl = ""
    $authToken = ""
    $model = ""

    switch ($apiChoice) {
        0 {
            $baseUrl = "https://ark.cn-beijing.volces.com/api/coding"
            $authToken = Get-UserInput "Enter Volcengine API Key"
            $modelChoice = Get-UserChoice "Select default model:" @(
                "doubao-seed-code-preview-latest (Doubao Code)",
                "ark-code-latest (DeepSeek V3.2)",
                "glm-5.1 (GLM)",
                "doubao-seed-2.0-pro (Doubao 2.0 Pro)"
            )
            $models = @("doubao-seed-code-preview-latest", "ark-code-latest", "glm-5.1", "doubao-seed-2.0-pro")
            $model = $models[$modelChoice]
        }
        1 {
            $baseUrl = ""
            $authToken = Get-UserInput "Enter Anthropic API Key (sk-ant-...)"
            $model = "claude-sonnet-4-20250514"
        }
        2 {
            $baseUrl = "https://openrouter.ai/api/v1"
            $authToken = Get-UserInput "Enter OpenRouter API Key"
            $model = "anthropic/claude-sonnet-4-20250514"
        }
        3 {
            Write-Info "Skipping API config"
        }
    }

    if ($authToken) {
        Write-Info "Writing settings.json..."
        $settings = @{
            env = @{
                ANTHROPIC_AUTH_TOKEN = $authToken
                ANTHROPIC_MODEL = $model
                API_TIMEOUT_MS = "600000"
                CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1"
            }
            theme = "dark"
            permissions = @{
                allow = @(
                    "Bash(git:*)", "Bash(npm:*)", "Bash(npx:*)", "Bash(node:*)", "Bash(pnpm:*)",
                    "Bash(python:*)", "Bash(pip:*)", "Bash(uv:*)",
                    "Bash(ls:*)", "Bash(cat:*)", "Bash(echo:*)", "Bash(mkdir:*)",
                    "Bash(dir:*)", "Bash(type:*)", "Bash(find:*)", "Bash(grep:*)",
                    "Bash(head:*)", "Bash(tail:*)", "Bash(wc:*)", "Bash(sort:*)",
                    "Bash(docker:*)", "Bash(kubectl:*)",
                    "Bash(cargo:*)", "Bash(go:*)",
                    "Read", "Write", "Edit", "MultiEdit", "Glob", "Grep", "LS"
                )
                deny = @("Bash(rm -rf:*)", "Bash(format:*)", "Bash(del /s:*)", "Bash(sudo rm:*)")
            }
        }
        if ($baseUrl) {
            $settings.env.ANTHROPIC_BASE_URL = $baseUrl
        }
        if (-not $DryRun) {
            $settings | ConvertTo-Json -Depth 5 | Set-Content "$CLAUDE_DIR\settings.json" -Encoding UTF8
        }
        Write-Ok "settings.json written"
    }
}

# Step 6: Generate CLAUDE.md
Write-Step "Step 6/11: Generate CLAUDE.md"

$claudeMdPath = "$CLAUDE_DIR\CLAUDE.md"
if (-not (Test-Path $claudeMdPath) -and -not $DryRun) {
    $templatePath = "$PROJECT_DIR\config\CLAUDE.md"
    if (Test-Path $templatePath) {
        Copy-Item $templatePath $claudeMdPath -Force
        Write-Ok "CLAUDE.md copied from template"
    } else {
        Write-Warn "CLAUDE.md template not found"
    }
} elseif (Test-Path $claudeMdPath) {
    Write-Ok "CLAUDE.md already exists"
}

# Step 7: Install Superpowers Skills (from GitHub)
Write-Step "Step 7/11: Install Superpowers Skills"

if ($SkipSuperpowers) {
    Write-Info "Skipping Superpowers (-SkipSuperpowers)"
} else {
    if (Test-Path $SUPERPOWERS_DIR) {
        Write-Info "Updating Superpowers..."
        Push-Location $SUPERPOWERS_DIR
        git pull
        Pop-Location
        Write-Ok "Superpowers updated"
    } else {
        Write-Info "Cloning Superpowers from GitHub..."
        if (-not $DryRun) {
            git clone https://github.com/obra/superpowers.git $SUPERPOWERS_DIR
        }
        Write-Ok "Superpowers installed to: $SUPERPOWERS_DIR"
    }

    $pluginsJson = "$CLAUDE_DIR\plugins.json"
    $pluginConfig = @{
        plugins = @{
            superpowers = @{
                type = "local"
                path = $SUPERPOWERS_DIR
            }
        }
    }
    if (-not $DryRun) {
        $pluginConfig | ConvertTo-Json -Depth 3 | Set-Content $pluginsJson -Encoding UTF8
    }
    Write-Ok "plugins.json written"
}

# Step 8: Install additional plugins
Write-Step "Step 8/11: Install additional plugins"

if ($SkipPlugins) {
    Write-Info "Skipping plugins (-SkipPlugins)"
} elseif (-not (Test-Command "claude")) {
    Write-Warn "Claude Code not installed, skipping plugins"
} else {
    $pluginsConfPath = "$PROJECT_DIR\config\plugins.conf"
    if (Test-Path $pluginsConfPath) {
        $plugins = Get-Content $pluginsConfPath | Where-Object {
            $_ -match '\S' -and $_ -notmatch '^\s*#'
        } | ForEach-Object {
            ($_ -split '#')[0].Trim()
        } | Where-Object { $_ -ne '' -and $_ -ne 'superpowers@claude-plugins-official' }

        Write-Info "Installing $($plugins.Count) plugins..."
        $installed = 0
        foreach ($plugin in $plugins) {
            Write-Info "  $plugin ..."
            if (-not $DryRun) {
                try {
                    & claude plugin install $plugin 2>&1 | Out-Null
                    $installed++
                } catch {}
            }
        }
        Write-Ok "$installed plugins installed"
    } else {
        Write-Warn "plugins.conf not found"
    }
}

# Step 9: Register MCP servers
Write-Step "Step 9/11: Register MCP servers"

if ($SkipMCP) {
    Write-Info "Skipping MCP config (-SkipMCP)"
} else {
    $mcpChoice = Get-UserChoice "Select MCP server preset:" @(
        "Recommended (Context7 + Sequential-Thinking + Fetch + Memory)",
        "Full (Recommended + Playwright + GitHub)",
        "Minimal (Sequential-Thinking only)",
        "Skip"
    )

    $mcpServers = @{}

    switch ($mcpChoice) {
        0 {
            $mcpServers = @{
                context7 = @{ command = "npx"; args = @("-y", "@upstash/context7-mcp") }
                "sequential-thinking" = @{ command = "npx"; args = @("-y", "@modelcontextprotocol/server-sequential-thinking") }
                fetch = @{ command = "npx"; args = @("-y", "@modelcontextprotocol/server-fetch") }
                memory = @{ command = "npx"; args = @("-y", "@modelcontextprotocol/server-memory") }
            }
        }
        1 {
            $mcpServers = @{
                context7 = @{ command = "npx"; args = @("-y", "@upstash/context7-mcp") }
                "sequential-thinking" = @{ command = "npx"; args = @("-y", "@modelcontextprotocol/server-sequential-thinking") }
                fetch = @{ command = "npx"; args = @("-y", "@modelcontextprotocol/server-fetch") }
                memory = @{ command = "npx"; args = @("-y", "@modelcontextprotocol/server-memory") }
                playwright = @{ command = "npx"; args = @("-y", "@playwright/mcp@latest") }
                github = @{ command = "npx"; args = @("-y", "@modelcontextprotocol/server-github") }
            }
        }
        2 {
            $mcpServers = @{
                "sequential-thinking" = @{ command = "npx"; args = @("-y", "@modelcontextprotocol/server-sequential-thinking") }
            }
        }
    }

    if ($mcpServers.Count -gt 0 -and -not $DryRun) {
        @{ mcpServers = $mcpServers } | ConvertTo-Json -Depth 3 | Set-Content "$CLAUDE_DIR\mcp.json" -Encoding UTF8
        Write-Ok "mcp.json written ($($mcpServers.Count) servers)"
    }
}

# Step 10: Verify installation
Write-Step "Step 10/11: Verify installation"

$checks = @(
    @{ Name = "Claude Code CLI"; Test = { Test-Command "claude" } },
    @{ Name = "settings.json"; Test = { Test-Path "$CLAUDE_DIR\settings.json" } },
    @{ Name = "CLAUDE.md"; Test = { Test-Path "$CLAUDE_DIR\CLAUDE.md" } },
    @{ Name = "Superpowers"; Test = { Test-Path $SUPERPOWERS_DIR } },
    @{ Name = "plugins.json"; Test = { Test-Path "$CLAUDE_DIR\plugins.json" } },
    @{ Name = "mcp.json"; Test = { Test-Path "$CLAUDE_DIR\mcp.json" } }
)

$allOk = $true
foreach ($check in $checks) {
    if (& $check.Test) {
        Write-Ok $check.Name
    } else {
        Write-Warn "$($check.Name) - not ready"
        $allOk = $false
    }
}

# Step 11: Complete
Write-Step "Step 11/11: Complete"

Write-Host ""
Write-Host "============================================" -ForegroundColor Magenta
if ($allOk) {
    Write-Host "  Installation complete!" -ForegroundColor Green
} else {
    Write-Host "  Installation complete (some items need attention)" -ForegroundColor Yellow
}
Write-Host "============================================" -ForegroundColor Magenta
Write-Host ""
Write-Info "Next steps:"
Write-Info "  1. Open a new terminal window"
Write-Info "  2. Run 'claude' to start"
Write-Info "  3. Enter /status to verify"
Write-Info "  4. Enter /find-skills to see Skills"
Write-Host ""
Write-Info "Update:  cd $PROJECT_DIR ; .\scripts\update.ps1"
Write-Info "Fix Git: .\scripts\fix-git.ps1"
Write-Info "API:     .\scripts\setup_api.ps1"
Write-Info "MCP:     .\scripts\setup_mcp.ps1"
