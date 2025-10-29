<#+
.SYNOPSIS
    Installs ShellCheck on Windows using the first available package provider.
.DESCRIPTION
    Attempts installation with winget, Chocolatey, or Scoop. Verifies success afterwards.
#>
[CmdletBinding()]
param()

function Write-Log {
    param(
        [Parameter(Mandatory)][string]$Message
    )
    Write-Host "[ShellCheck Installer] $Message"
}

function Install-WithWinget {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        return $false
    }

    Write-Log "Installing ShellCheck with winget..."
    winget install --id=koalaman.shellcheck -e
    return $true
}

function Install-WithChoco {
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        return $false
    }

    Write-Log "Installing ShellCheck with Chocolatey..."
    choco install shellcheck -y
    return $true
}

function Install-WithScoop {
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        return $false
    }

    Write-Log "Installing ShellCheck with Scoop..."
    scoop install shellcheck
    return $true
}

if (Get-Command shellcheck -ErrorAction SilentlyContinue) {
    Write-Log "ShellCheck is already installed at $(Get-Command shellcheck | Select-Object -ExpandProperty Source)."
    return
}

$installed = $false

$installed = Install-WithWinget
if (-not $installed) {
    $installed = Install-WithChoco
}
if (-not $installed) {
    $installed = Install-WithScoop
}

if (-not $installed) {
    Write-Log "Unable to find winget, Chocolatey, or Scoop. Please install ShellCheck manually from https://www.shellcheck.net/."
    exit 1
}

if (Get-Command shellcheck -ErrorAction SilentlyContinue) {
    Write-Log "ShellCheck installation completed successfully."
} else {
    Write-Log "ShellCheck installation command finished, but shellcheck is still unavailable on PATH."
    exit 1
}
