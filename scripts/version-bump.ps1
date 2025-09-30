#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Semantic version management script for nMapping+
    
.DESCRIPTION
    This script helps manage semantic versioning for the nMapping+ project.
    It can bump versions, update changelogs, and create git tags.
    
.PARAMETER Type
    Type of version bump: patch, minor, major
    
.PARAMETER Version
    Specific version to set (e.g., "0.2.0")
    
.PARAMETER DryRun
    Preview changes without applying them
    
.EXAMPLE
    .\version-bump.ps1 -Type patch
    Bumps the patch version (0.1.0 -> 0.1.1)
    
.EXAMPLE
    .\version-bump.ps1 -Version "0.2.0"
    Sets the version to 0.2.0
    
.EXAMPLE
    .\version-bump.ps1 -Type minor -DryRun
    Preview a minor version bump without applying changes
#>

param(
    [Parameter(ParameterSetName = "Bump")]
    [ValidateSet("patch", "minor", "major")]
    [string]$Type,
    
    [Parameter(ParameterSetName = "Set")]
    [string]$Version,
    
    [switch]$DryRun
)

# Color output functions
function Write-Success { param($Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Info { param($Message) Write-Host "ℹ️  $Message" -ForegroundColor Blue }
function Write-Warning { param($Message) Write-Host "⚠️  $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "❌ $Message" -ForegroundColor Red }

# Get current directory
$ProjectRoot = $PSScriptRoot
if (-not $ProjectRoot) {
    $ProjectRoot = Get-Location
}

# File paths
$PackageJsonPath = Join-Path $ProjectRoot "package.json"
$ChangelogPath = Join-Path $ProjectRoot "CHANGELOG.md"
$ReadmePath = Join-Path $ProjectRoot "README.md"

function Get-CurrentVersion {
    if (-not (Test-Path $PackageJsonPath)) {
        Write-Error "package.json not found at $PackageJsonPath"
        exit 1
    }
    
    $packageJson = Get-Content $PackageJsonPath | ConvertFrom-Json
    return $packageJson.version
}

function Set-Version {
    param([string]$NewVersion)
    
    Write-Info "Setting version to $NewVersion"
    
    # Update package.json
    if (Test-Path $PackageJsonPath) {
        $packageJson = Get-Content $PackageJsonPath | ConvertFrom-Json
        $packageJson.version = $NewVersion
        $packageJson | ConvertTo-Json -Depth 10 | Set-Content $PackageJsonPath
        Write-Success "Updated package.json"
    }
    
    # Update CHANGELOG.md if exists
    if (Test-Path $ChangelogPath) {
        $changelogContent = Get-Content $ChangelogPath -Raw
        $today = Get-Date -Format "yyyy-MM-dd"
        
        # Replace [Unreleased] with new version
        $updatedChangelog = $changelogContent -replace '\[Unreleased\]', "[$NewVersion] - $today"
        
        # Add new Unreleased section
        $unreleasedSection = @"
## [Unreleased]

### Added
### Changed  
### Deprecated
### Removed
### Fixed
### Security

## [$NewVersion] - $today
"@
        
        $updatedChangelog = $updatedChangelog -replace "## \[$NewVersion\] - $today", $unreleasedSection
        
        Set-Content $ChangelogPath $updatedChangelog
        Write-Success "Updated CHANGELOG.md"
    }
}

function Get-NextVersion {
    param(
        [string]$CurrentVersion,
        [string]$BumpType
    )
    
    if ($CurrentVersion -notmatch '^(\d+)\.(\d+)\.(\d+)(-.*)?$') {
        Write-Error "Invalid version format: $CurrentVersion"
        exit 1
    }
    
    $major = [int]$Matches[1]
    $minor = [int]$Matches[2]
    $patch = [int]$Matches[3]
    
    switch ($BumpType) {
        "major" { 
            $major++
            $minor = 0
            $patch = 0
        }
        "minor" { 
            $minor++
            $patch = 0
        }
        "patch" { 
            $patch++
        }
    }
    
    return "$major.$minor.$patch"
}

function Test-GitStatus {
    try {
        $gitStatus = git status --porcelain 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Not in a git repository or git not available"
            return $false
        }
        
        if ($gitStatus) {
            Write-Warning "Working directory has uncommitted changes:"
            git status --short
            return $false
        }
        
        return $true
    }
    catch {
        Write-Warning "Git status check failed: $_"
        return $false
    }
}

function New-GitTag {
    param([string]$Version)
    
    $tagName = "v$Version"
    
    try {
        # Create annotated tag
        git tag -a $tagName -m "Release version $Version"
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Created git tag: $tagName"
            Write-Info "Push tag with: git push origin $tagName"
        } else {
            Write-Error "Failed to create git tag"
        }
    }
    catch {
        Write-Error "Error creating git tag: $_"
    }
}

function Show-VersionInfo {
    param([string]$CurrentVersion, [string]$NewVersion)
    
    Write-Host "`n📦 Version Information" -ForegroundColor Cyan
    Write-Host "═══════════════════════" -ForegroundColor Cyan
    Write-Host "Current Version: " -NoNewline
    Write-Host $CurrentVersion -ForegroundColor Yellow
    Write-Host "New Version:     " -NoNewline
    Write-Host $NewVersion -ForegroundColor Green
    Write-Host ""
}

# Main script logic
Write-Host "🚀 nMapping+ Version Management" -ForegroundColor Magenta
Write-Host "═══════════════════════════════" -ForegroundColor Magenta

# Check if in project root
if (-not (Test-Path $PackageJsonPath)) {
    Write-Error "package.json not found. Make sure you're in the project root directory."
    exit 1
}

$currentVersion = Get-CurrentVersion
Write-Info "Current version: $currentVersion"

# Determine new version
if ($Version) {
    $newVersion = $Version
} elseif ($Type) {
    $newVersion = Get-NextVersion -CurrentVersion $currentVersion -BumpType $Type
} else {
    Write-Error "Please specify either -Type (patch/minor/major) or -Version"
    exit 1
}

# Validate new version format
if ($newVersion -notmatch '^\d+\.\d+\.\d+(-.*)?$') {
    Write-Error "Invalid version format: $newVersion"
    exit 1
}

# Show version information
Show-VersionInfo -CurrentVersion $currentVersion -NewVersion $newVersion

# Check git status
$gitClean = Test-GitStatus

if ($DryRun) {
    Write-Warning "DRY RUN MODE - No changes will be applied"
    Write-Info "Would update version from $currentVersion to $newVersion"
    Write-Info "Files that would be modified:"
    Write-Host "  • package.json" -ForegroundColor Gray
    if (Test-Path $ChangelogPath) { Write-Host "  • CHANGELOG.md" -ForegroundColor Gray }
    if ($gitClean) {
        Write-Host "  • Git tag: v$newVersion" -ForegroundColor Gray
    }
    exit 0
}

# Confirm action
Write-Host "`n⚠️  This will update version files and create a git tag." -ForegroundColor Yellow
$confirm = Read-Host "Continue? (y/N)"
if ($confirm -notin @('y', 'Y', 'yes', 'Yes', 'YES')) {
    Write-Info "Operation cancelled"
    exit 0
}

# Apply version changes
try {
    Set-Version -NewVersion $newVersion
    
    # Commit changes if in git repo and working directory was clean
    if ($gitClean) {
        git add package.json CHANGELOG.md 2>$null
        git commit -m "chore: bump version to $newVersion"
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Committed version changes"
            New-GitTag -Version $newVersion
        }
    }
    
    Write-Success "Version successfully updated to $newVersion"
    
    # Show next steps
    Write-Host "`n🎯 Next Steps:" -ForegroundColor Cyan
    Write-Host "═══════════════" -ForegroundColor Cyan
    if ($gitClean) {
        Write-Host "1. Push changes: " -NoNewline
        Write-Host "git push" -ForegroundColor Yellow
        Write-Host "2. Push tag:     " -NoNewline  
        Write-Host "git push origin v$newVersion" -ForegroundColor Yellow
    } else {
        Write-Host "1. Review changes in package.json and CHANGELOG.md"
        Write-Host "2. Commit changes when ready"
        Write-Host "3. Create git tag: git tag v$newVersion"
    }
    Write-Host "3. GitHub will automatically create a release from the tag"
    
} catch {
    Write-Error "Failed to update version: $_"
    exit 1
}

Write-Host "`n✨ Version bump completed successfully!" -ForegroundColor Green