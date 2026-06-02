# fix-git.ps1 - Fix Git GitHub connection (Windows)
# Auto detect: SSH available -> HTTPS to SSH | Proxy available -> Configure proxy

$ErrorActionPreference = "Stop"

function Write-Info($msg)  { Write-Host "[INFO] $msg" -ForegroundColor Blue }
function Write-OK($msg)    { Write-Host "[OK] $msg" -ForegroundColor Green }
function Write-Warn($msg)  { Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Fail($msg)  { Write-Host "[FAIL] $msg" -ForegroundColor Red }

function Test-GitHubHttps {
    Write-Info "Testing GitHub HTTPS connection..."
    try {
        $result = & git ls-remote https://github.com/anthropics/claude-code.git HEAD 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-OK "GitHub HTTPS connection OK"
            return $true
        }
    } catch {}
    Write-Warn "GitHub HTTPS connection failed"
    return $false
}

function Test-GitHubSsh {
    Write-Info "Testing GitHub SSH connection..."
    try {
        $result = & ssh -T git@github.com 2>&1
        if ($result -match "successfully authenticated") {
            Write-OK "GitHub SSH connection OK"
            return $true
        }
    } catch {}
    Write-Warn "GitHub SSH connection failed (SSH key may not be configured)"
    return $false
}

function Find-LocalProxy {
    Write-Info "Detecting local proxy..."
    $proxyVars = @("ALL_PROXY", "all_proxy", "http_proxy", "https_proxy", "HTTPS_PROXY", "HTTP_PROXY")
    foreach ($var in $proxyVars) {
        $val = [Environment]::GetEnvironmentVariable($var, "User")
        if (-not $val) { $val = [Environment]::GetEnvironmentVariable($var, "Machine") }
        if ($val) {
            Write-OK "Found proxy env var: $var=$val"
            return "env:$val"
        }
    }
    $ports = @(1080, 1081, 7890, 7891, 10808, 10809)
    foreach ($port in $ports) {
        try {
            $conn = Test-NetConnection -ComputerName 127.0.0.1 -Port $port -WarningAction SilentlyContinue -InformationLevel Quiet
            if ($conn) {
                Write-OK "Found listening port: 127.0.0.1:$port"
                return "socks5h://127.0.0.1:$port"
            }
        } catch {}
    }
    Write-Warn "No local proxy found"
    return $null
}

function Fix-WithSsh {
    Write-Info "Configuring Git to use SSH instead of HTTPS for GitHub..."
    & git config --global url."git@github.com:".insteadOf "https://github.com/"
    & git config --global --unset http.proxy 2>$null
    & git config --global --unset https.proxy 2>$null
    try {
        & git ls-remote https://github.com/anthropics/claude-code.git HEAD 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-OK "Git SSH configuration successful"
            return $true
        }
    } catch {}
    Write-Warn "SSH verification failed, reverting..."
    & git config --global --unset url."git@github.com:".insteadOf
    return $false
}

function Fix-WithProxy($proxyUrl) {
    Write-Info "Configuring Git to use proxy: $proxyUrl..."
    & git config --global http.proxy $proxyUrl
    & git config --global https.proxy $proxyUrl
    try {
        & git ls-remote https://github.com/anthropics/claude-code.git HEAD 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-OK "Git proxy configuration successful"
            return $true
        }
    } catch {}
    Write-Warn "Proxy verification failed, reverting..."
    & git config --global --unset http.proxy 2>$null
    & git config --global --unset https.proxy 2>$null
    return $false
}

Write-Host ""
Write-Host "============================================================"
Write-Host "  Git GitHub Connection Fix Tool (Windows)"
Write-Host "============================================================"
Write-Host ""

if (Test-GitHubHttps) {
    Write-OK "No fix needed, Git GitHub connection OK"
    exit 0
}

Write-Host ""

if (Test-GitHubSsh) {
    Write-Host ""
    if (Fix-WithSsh) { exit 0 }
}

Write-Host ""

$proxy = Find-LocalProxy
if ($proxy) {
    Write-Host ""
    if ($proxy -like "env:*") {
        $url = $proxy.Substring(4)
        if (Fix-WithProxy $url) { exit 0 }
    } else {
        if (Fix-WithProxy $proxy) { exit 0 }
    }
}

Write-Host ""
Write-Fail "All auto-fix methods failed, please check manually:"
Write-Host ""
Write-Host "  1. Configure SSH key: ssh-keygen -t ed25519"
Write-Host "  2. Configure proxy: git config --global http.proxy socks5h://127.0.0.1:<port>"
Write-Host "  3. Check network/firewall settings"
Write-Host ""
exit 1
