# setup-nmapping-plus.ps1
# Professional GitHub setup script for nMapping+
# Author: Thomas Wheeler (th3Wheel)
# Email: tnwheeler@gmail.com
#
# This script automates the initial GitHub setup for the nMapping+ project.
# It configures git, sets up the remote, and pushes the initial commit.
#
# Requirements:
# - Git installed and in PATH
# - (Optional) GitHub CLI (gh) for repo creation


param(
    [string]$RepoName = "nmapping-plus",
    [string]$GitHubUser = "th3Wheel",
    [string]$UserName = "Thomas Wheeler",
    [string]$UserEmail = "tnwheeler@gmail.com"
)

$ErrorActionPreference = 'Stop'

# --- Edge Case Checks ---
# 1. Check for required tools
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error "Git is not installed or not in PATH. Aborting."; exit 1
}
if (-not (Test-Path .)) { Write-Error "Current directory not found."; exit 1 }

# 2. Check for project root
if (-not (Test-Path .git)) {
    Write-Warning "No .git directory found. Are you in the project root?"
    $resp = Read-Host "Continue and initialize a new git repo here? (y/n)"
    if ($resp -ne 'y') { exit 1 }
    git init
}

# 3. Check for large files
$largeFiles = Get-ChildItem -Recurse -File | Where-Object { $_.Length -gt 100MB }
if ($largeFiles) {
    Write-Warning "Large files detected (>100MB):"
    $largeFiles | ForEach-Object { Write-Host $_.FullName }
    Write-Host "Consider using Git LFS for large files."
}

git config user.email "$UserEmail"

Write-Host "--- nMapping+ GitHub Setup Script ---" -ForegroundColor Cyan

# Step 1: Set git user config
git config user.name "$UserName"
git config user.email "$UserEmail"
Write-Host "Git user.name and user.email set."

# Step 2: Check if remote exists or conflicts
$remoteUrl = "https://github.com/$GitHubUser/$RepoName.git"
$existingRemote = git remote get-url origin 2>$null
if ($existingRemote) {
    if ($existingRemote -ne $remoteUrl) {
        Write-Warning "Remote 'origin' points to a different URL: $existingRemote"
        $resp = Read-Host "Update 'origin' to $remoteUrl? (y/n)"
        if ($resp -eq 'y') {
            git remote set-url origin $remoteUrl
            Write-Host "Remote 'origin' updated."
        } else {
            Write-Host "Keeping existing remote."
        }
    } else {
        Write-Host "Remote 'origin' already set to: $existingRemote"
    }
} else {
    Write-Host "Adding remote 'origin': $remoteUrl"
    git remote add origin $remoteUrl
}

# Step 3: Create repo on GitHub (if gh CLI is available)
if (-not (git ls-remote --exit-code $remoteUrl 2>$null)) {
    if (Get-Command gh -ErrorAction SilentlyContinue) {
        Write-Host "Creating GitHub repo via gh CLI..."
        gh repo create "$GitHubUser/$RepoName" --public --description "Professional self-hosted network mapping with real-time dashboard" --source . --remote origin --push
    } else {
        Write-Warning "GitHub repo does not exist and gh CLI not found. Please create the repo manually: $remoteUrl"
    }
}

# Step 4: Stage and commit files if not already committed
$status = git status --porcelain
if ($status) {
    Write-Host "Staging and committing all changes..."
    git add .
    try {
        git commit -m "feat: Initial nMapping+ v1.0.0 release`n`nComplete professional network mapping solution with:`n- Dual-container architecture (scanner + dashboard)`n- Proxmox VE Community Scripts integration`n- Real-time web dashboard with Flask/WebSocket`n- Git-based change tracking system`n- Comprehensive documentation and CI/CD pipeline"
    } catch {
        Write-Warning "Nothing to commit or commit failed: $_"
    }
} else {
    Write-Host "No changes to commit."
}

# Step 5: Detect current branch and push to GitHub
$currentBranch = git rev-parse --abbrev-ref HEAD
Write-Host "Pushing to GitHub branch '$currentBranch'..."
try {
    git push -u origin $currentBranch
    Write-Host "--- nMapping+ GitHub setup complete! ---" -ForegroundColor Green
} catch {
    Write-Error "Push failed. Check your network connection, authentication, and remote repo permissions."
}
