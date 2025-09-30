# Semantic Versioning Guide for nMapping+

This document explains how to use semantic versioning in the nMapping+ project.

## Overview

nMapping+ follows [Semantic Versioning 2.0.0](https://semver.org/) specification:

- **MAJOR.MINOR.PATCH** format (e.g., 0.1.0)
- **MAJOR**: Breaking changes that require user action
- **MINOR**: New features that are backward compatible  
- **PATCH**: Bug fixes and minor improvements

## Current Version

The project is currently at version **0.1.0** (initial development phase).

## Version Management Tools

### 1. NPM Scripts (Recommended)

```bash
# Patch version bump (0.1.0 -> 0.1.1)
npm run release:patch

# Minor version bump (0.1.0 -> 0.2.0)  
npm run release:minor

# Major version bump (0.1.0 -> 1.0.0)
npm run release:major
```

### 2. PowerShell Script

```powershell
# Patch version bump
.\scripts\version-bump.ps1 -Type patch

# Minor version bump  
.\scripts\version-bump.ps1 -Type minor

# Major version bump
.\scripts\version-bump.ps1 -Type major

# Set specific version
.\scripts\version-bump.ps1 -Version "0.2.0"

# Preview changes without applying
.\scripts\version-bump.ps1 -Type minor -DryRun
```

### 3. Manual Version Updates

1. Update `package.json` version field
2. Update `CHANGELOG.md` with new version and release date
3. Commit changes: `git commit -m "chore: bump version to X.Y.Z"`
4. Create git tag: `git tag -a vX.Y.Z -m "Release version X.Y.Z"`
5. Push changes and tag: `git push && git push --tags`

## Conventional Commits

We use [Conventional Commits](https://www.conventionalcommits.org/) for automatic changelog generation:

### Commit Types

- `feat:` - New features (triggers MINOR bump)
- `fix:` - Bug fixes (triggers PATCH bump) 
- `docs:` - Documentation changes
- `style:` - Code style changes (formatting, etc.)
- `refactor:` - Code refactoring without feature changes
- `test:` - Adding or updating tests
- `chore:` - Maintenance tasks, dependency updates
- `ci:` - CI/CD pipeline changes
- `perf:` - Performance improvements
- `build:` - Build system changes

### Breaking Changes

Add `BREAKING CHANGE:` in commit footer to trigger MAJOR version bump:

```
feat: redesign scanning API

BREAKING CHANGE: The scan() function now requires a configuration object instead of individual parameters.
```

### Examples

```bash
# Features (minor bump)
git commit -m "feat: add real-time device discovery"
git commit -m "feat(dashboard): implement network topology view"

# Bug fixes (patch bump)  
git commit -m "fix: resolve memory leak in scanner"
git commit -m "fix(api): handle invalid IP addresses correctly"

# Documentation
git commit -m "docs: update installation guide"
git commit -m "docs(readme): add troubleshooting section"

# Chores
git commit -m "chore: update dependencies"
git commit -m "chore(scripts): improve deployment automation"
```

## Release Process

### Automated Releases (GitHub)

1. **Push to main branch** with conventional commits
2. **Release Please** automatically creates a PR with version bump
3. **Merge the PR** to trigger automatic release
4. **GitHub Release** is created with changelog

### Manual Releases

1. **Update version** using scripts or manually
2. **Update CHANGELOG.md** with release notes
3. **Commit and tag** the release
4. **Push changes** to trigger CI/CD
5. **Create GitHub release** from tag

## File Updates During Release

When bumping versions, these files are automatically updated:

- `package.json` - Version field
- `CHANGELOG.md` - New release section with date
- Git tags - New annotated tag (e.g., v0.2.0)

## Development Phases

### Pre-1.0.0 (Current)

- **0.x.y versions** for initial development
- **Breaking changes allowed** without major version bump
- **Rapid iteration** and feature development

### Post-1.0.0 (Future)

- **Stable API** with semantic versioning guarantees
- **Breaking changes** only in major versions
- **Backward compatibility** maintained in minor/patch

## Version Branching Strategy

### Main Branch

- **main/master** - Production-ready code
- **All releases** tagged from main branch
- **Direct commits** for hotfixes only

### Development

- **Feature branches** for new development
- **Pull requests** required for main branch
- **Version bumps** only on main branch

### Hotfixes

- **Patch releases** for critical fixes
- **Direct to main** with immediate release
- **Cherry-pick** to development branches if needed

## Changelog Management

### Format

Following [Keep a Changelog](https://keepachangelog.com/) format:

```markdown
## [Unreleased]
### Added
### Changed  
### Deprecated
### Removed
### Fixed
### Security

## [0.2.0] - 2025-10-15
### Added
- Real-time device discovery
- Network topology visualization

### Fixed  
- Memory leak in scanner process
```

### Categories

- **Added** - New features
- **Changed** - Changes in existing functionality
- **Deprecated** - Soon-to-be removed features
- **Removed** - Removed features
- **Fixed** - Bug fixes
- **Security** - Security vulnerabilities

### Automation

- **Automatic generation** from conventional commits
- **Manual enhancement** for release notes
- **Version links** at bottom of file

## Best Practices

### Before Releasing

1. **Review CHANGELOG.md** for completeness
2. **Test all functionality** thoroughly  
3. **Update documentation** as needed
4. **Check for breaking changes**
5. **Verify version number** is appropriate

### During Development

1. **Use conventional commits** consistently
2. **Update CHANGELOG.md** for significant changes
3. **Test version bump scripts** before releases
4. **Keep git history clean** with meaningful commits

### After Releasing

1. **Verify GitHub release** was created
2. **Test installation** from release package
3. **Update dependent projects** if needed
4. **Announce release** to users/community

## Troubleshooting

### Version Mismatch

If package.json and git tags are out of sync:

```bash
# Check current versions
git describe --tags
npm version --no-git-tag-version

# Fix by setting consistent version
npm version X.Y.Z --no-git-tag-version
git tag vX.Y.Z
```

### Failed Release

If automated release fails:

1. Check GitHub Actions logs
2. Verify conventional commit format
3. Ensure proper branch protection rules
4. Manual release as fallback

### Changelog Issues

If changelog generation fails:

```bash
# Regenerate manually
npm run changelog
git add CHANGELOG.md
git commit -m "docs: update changelog"
```

## Resources

- [Semantic Versioning Specification](https://semver.org/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Keep a Changelog](https://keepachangelog.com/)
- [Release Please](https://github.com/googleapis/release-please)

## Examples

### Complete Release Workflow

```bash
# 1. Create feature branch
git checkout -b feat/network-topology

# 2. Make changes with conventional commits
git commit -m "feat: add network topology visualization"
git commit -m "test: add topology rendering tests"
git commit -m "docs: document topology API"

# 3. Create pull request and merge to main

# 4. Bump version (triggers automated release)
npm run release:minor

# 5. Verify release on GitHub
```

This system ensures consistent, predictable version management for the nMapping+ project.