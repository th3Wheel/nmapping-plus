
# GitHub Repository Setup Guide

## ✅ Pre-Flight Checklist

- [ ] **Git installed and in PATH**
- [ ] **(Optional) GitHub CLI (`gh`) installed** for repo creation
- [ ] **In the project root** (where `.git` and main files are)
- [ ] **No large files (>100MB)** unless using Git LFS
- [ ] **Network connection and GitHub authentication**
- [ ] **No merge conflicts or uncommitted changes**
- [ ] **Remote 'origin' points to your intended GitHub repo**

> **Tip:** Run the setup script from the project root for best results.

## 🚀 Quick GitHub Setup

This guide will help you connect your local nMapping+ repository to GitHub and set up the complete development workflow.

### Prerequisites

- [GitHub account](https://github.com) (free account is sufficient)
- Git installed and configured on your system
- SSH keys configured for GitHub (recommended) or HTTPS authentication


---

### Step 1: Create GitHub Repository

1. **Go to GitHub**: Navigate to [https://github.com/new](https://github.com/new)

2. **Repository Details**:
   - **Repository Name**: `nmapping-plus` (recommended) or your preferred name
   - **Description**: "Professional self-hosted network mapping with real-time dashboard"
   - **Visibility**: Choose Public (recommended for community) or Private
   - **Initialize**: Do NOT initialize with README, .gitignore, or license (we already have these)

3. **Click "Create Repository"**


---

### Step 2: Update Repository URLs

After creating your GitHub repository, update the placeholder URLs in your local files:

1. **Find and replace** in the following files:
   - `README.md`
   - `docs/index.md`
   - `CHANGELOG.md`
 
   https://github.com/YOUR_USERNAME/nmapping-plus
   ```
   
   **Example**: If your GitHub username is `johnsmith`, replace with:
   ```
   https://github.com/johnsmith/nmapping-plus
   ```


---

### Step 3: Configure Git User (One-time Setup)
> **Warning:** If you do not set your user.name and user.email, commits may be rejected or show as anonymous.

```bash
# Set your name and email for commits
git config --global user.name "Your Full Name"
git config --global user.email "your.email@example.com"

# Or set locally for just this repository
git config user.name "Your Full Name" 
git config user.email "your.email@example.com"
```


---

### Step 4: Create Initial Commit
> **Tip:** If there are no changes to commit, this step will do nothing. Only commit if you have staged changes.

```bash
# Ensure you're in the nMapping+ directory
cd nMapping+

# Check status (files should be staged)
git status

# Create initial commit
git commit -m "feat: Initial nMapping+ v1.0.0 release

Complete professional network mapping solution with:
- Dual-container architecture (scanner + dashboard)
- Proxmox VE Community Scripts integration  
- Real-time web dashboard with Flask/WebSocket
- Git-based change tracking system
- Comprehensive documentation and CI/CD pipeline"
```


---

### Step 5: Add Remote Repository
> **Warning:** If 'origin' already exists and points to a different URL, update it with:
> ```bash
> git remote set-url origin https://github.com/YOUR_USERNAME/nmapping-plus.git
> ```

Replace `YOUR_USERNAME` with your actual GitHub username:

```bash
# Add GitHub as remote origin
git remote add origin https://github.com/YOUR_USERNAME/nmapping-plus.git

# Verify remote was added
git remote -v
```


---

### Step 6: Push to GitHub
> **Tip:** If you see authentication errors, check your credentials and network connection.

```bash
# Push to GitHub (first time)
git push -u origin main

# For subsequent pushes, simply use:
git push
```

**Note**: If you get an error about the default branch name, you may need to rename your branch:

```bash
## Branch Name: main vs master

Depending on your git version and settings, your default branch may be named `main` or `master`.

**To check your current branch:**
```bash
git branch
```

**If your branch is `master`,** use `master` in all push/pull commands:
```bash
git push -u origin master
```

**If your branch is `main`,** use `main`:
```bash
git push -u origin main
```

**To rename your branch (optional):**
```bash
# Rename master to main
git branch -M main
git push -u origin main
```
```


---

### Step 7: Configure Branch Protection (Recommended)

1. **Go to your repository settings**: `https://github.com/YOUR_USERNAME/nmapping-plus/settings`

2. **Navigate to "Branches"** in the left sidebar

3. **Add branch protection rule** for `main`:
   - ☑️ Require a pull request before merging
   - ☑️ Require status checks to pass before merging
   - ☑️ Require branches to be up to date before merging
   - ☑️ Include administrators


---

### Step 8: Verify GitHub Features

#### GitHub Actions (CI/CD)
1. Go to the "Actions" tab in your repository
2. The workflow should run automatically on your first push
3. Check that all jobs complete successfully

#### Issue Templates
1. Go to "Issues" → "New Issue"
2. Verify you see templates for "Bug Report" and "Feature Request"

#### Pull Request Template
1. Create a test branch and make a small change
2. Open a pull request
3. Verify the PR template loads with all sections


---

### Step 9: Configure Repository Settings

#### General Settings
- ☑️ Enable "Issues"
- ☑️ Enable "Projects" (optional)
- ☑️ Enable "Discussions" (recommended for community)
- ☑️ Enable "Wiki" (optional)

#### Security Settings
- Enable "Dependency graph"
- Enable "Dependabot alerts"
- Enable "Dependabot security updates"
- Configure "Code scanning alerts" (optional)


---

### Step 10: Create First Release (Optional)

1. **Go to releases**: `https://github.com/YOUR_USERNAME/nmapping-plus/releases`

2. **Click "Create a new release"**:
   - **Tag version**: `v1.0.0`
   - **Release title**: `nMapping+ v1.0.0 - Initial Release`
   - **Description**: Use content from CHANGELOG.md
   - **Attach files**: Include any distribution packages if needed

3. **Publish release**


---

## 🔄 Daily Development Workflow

### Making Changes
```bash
# Create feature branch
git checkout -b feature/your-feature-name

# Make your changes
# ... edit files ...

# Add and commit changes
git add .
git commit -m "feat: add new feature description"

# Push branch to GitHub
git push -u origin feature/your-feature-name
```

### Creating Pull Request
1. Go to your GitHub repository
2. Click "Compare & pull request" button
3. Fill out the PR template
4. Submit for review

### Merging Changes
```bash
# Switch back to main branch
git checkout main

# Pull latest changes
git pull origin main

# Delete merged feature branch
git branch -d feature/your-feature-name
```


---

## 🔧 Advanced GitHub Configuration

### SSH Key Setup (Recommended)
```bash
# Generate SSH key (if you don't have one)
ssh-keygen -t ed25519 -C "your.email@example.com"

# Add to SSH agent
ssh-add ~/.ssh/id_ed25519

# Copy public key to clipboard
cat ~/.ssh/id_ed25519.pub
```

Then add the SSH key to your GitHub account at: https://github.com/settings/keys

### Use SSH Remote (More Secure)
```bash
# Change remote to SSH
git remote set-url origin git@github.com:YOUR_USERNAME/nmapping-plus.git
```

### GitHub CLI (Optional)
```bash
# Install GitHub CLI
# https://github.com/cli/cli#installation

# Authenticate
gh auth login

# Create repository directly from command line
gh repo create nmapping-plus --public --description "Professional self-hosted network mapping"
```


---

## 🌟 Community Features

### Enable Discussions
1. Go to repository Settings
2. Scroll down to "Features"
3. Check "Discussions"
4. Configure discussion categories

### Add Topics/Tags
1. Go to your repository main page
2. Click the gear icon next to "About"
3. Add relevant topics:
   - `network-monitoring`
   - `nmap`
   - `proxmox`
   - `flask`
   - `network-security`
   - `self-hosted`
   - `lxc`
   - `dashboard`

### Repository Description
Update the repository description to:
```
Professional self-hosted network mapping solution with real-time dashboard, built on Proxmox VE Community Scripts
```

### Add Website Link
Add your documentation or demo site URL in the repository settings.


---

## 📊 Repository Analytics

### Insights Tab
Monitor your repository activity through:
- **Traffic**: Visitor statistics
- **Commits**: Development activity
- **Community**: Health score
- **Dependency graph**: Package dependencies
- **Security**: Vulnerability alerts

### GitHub Stats
Consider adding repository stats to your README:
```markdown
![GitHub stars](https://img.shields.io/github/stars/YOUR_USERNAME/nmapping-plus)
![GitHub forks](https://img.shields.io/github/forks/YOUR_USERNAME/nmapping-plus)
![GitHub issues](https://img.shields.io/github/issues/YOUR_USERNAME/nmapping-plus)
![GitHub license](https://img.shields.io/github/license/YOUR_USERNAME/nmapping-plus)
```


---

## 🆘 Edge Cases & Troubleshooting

### Common Edge Cases

- **Not in project root:** Script or commands fail to find `.git` or main files. Always run from the project root.
- **Git or gh CLI not installed:** Install [Git](https://git-scm.com/) and optionally [GitHub CLI](https://cli.github.com/).
- **Remote 'origin' conflict:** If 'origin' points to a different repo, update it with `git remote set-url origin ...`.
- **Large files (>100MB):** Use [Git LFS](https://git-lfs.github.com/) for large files, or remove them before pushing.
- **No changes to commit:** If nothing is staged, `git commit` will do nothing. Make changes and `git add` first.
- **Authentication/network errors:** Check your credentials, SSH keys, and network connection.
- **Branch mismatch:** Check your current branch with `git branch` and push to the correct one (`main` or `master`).
- **Merge conflicts/uncommitted changes:** Resolve all conflicts and commit changes before pushing.
- **Repo already exists on GitHub:** Skip creation or use `gh repo create --source . --remote origin --push` to link.

### General Troubleshooting

- **Check status:**
   ```bash
   git status
   ```
- **Check remotes:**
   ```bash
   git remote -v
   ```
- **Check branch:**
   ```bash
   git branch
   ```
- **Check commit log:**
   ```bash
   git log --oneline
   ```
- **Check for large files:**
   ```bash
   git lfs ls-files
   ```

If you encounter issues not listed here, consult the [GitHub Docs](https://docs.github.com/) or open an issue in your repository.

### Common Issues

**Authentication Failed**
```bash
# For HTTPS, update credentials
git config --global credential.helper store

# For SSH, check key
ssh -T git@github.com
```

**Push Rejected**
```bash
# Force push (use with caution)
git push --force-with-lease

# Or fetch and merge
git fetch origin
git merge origin/main
```

**Large Files**
Consider using Git LFS for files >100MB:
```bash
git lfs install
git lfs track "*.db"
git add .gitattributes
```

### Getting Help
- **GitHub Docs**: https://docs.github.com/
- **Git Documentation**: https://git-scm.com/doc
- **Community Support**: Use GitHub Discussions in your repository

---

**🎉 Congratulations!** Your nMapping+ repository is now ready for collaborative development on GitHub!

For questions specific to this setup, create an issue in your repository using the Bug Report template.