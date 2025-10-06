#!/usr/bin/env bash
# install_shellcheck.sh -- Install ShellCheck across common Linux/macOS environments.

set -euo pipefail

log() {
    printf '[ShellCheck Installer] %s\n' "$1"
}

if command -v shellcheck >/dev/null 2>&1; then
    log "ShellCheck is already installed at $(command -v shellcheck)."
    exit 0
fi

install_with_apt() {
    log "Detected apt-based distribution. Installing shellcheck with apt." 
    sudo apt-get update -y
    sudo apt-get install -y shellcheck
}

install_with_dnf() {
    log "Detected dnf-based distribution. Installing shellcheck with dnf."
    sudo dnf install -y ShellCheck || sudo dnf install -y shellcheck
}

install_with_yum() {
    log "Detected yum-based distribution. Installing shellcheck with yum."
    if ! rpm -qa | grep -qi epel-release; then
        sudo yum install -y epel-release
    fi
    sudo yum install -y ShellCheck || sudo yum install -y shellcheck
}

install_with_pacman() {
    log "Detected pacman-based distribution. Installing shellcheck with pacman."
    sudo pacman -Sy --noconfirm shellcheck
}

install_with_zypper() {
    log "Detected zypper-based distribution. Installing shellcheck with zypper."
    sudo zypper refresh
    sudo zypper install -y ShellCheck || sudo zypper install -y shellcheck
}

install_with_apk() {
    log "Detected Alpine (apk). Installing shellcheck with apk."
    sudo apk add --no-cache shellcheck
}

install_with_brew() {
    log "Detected Homebrew. Installing shellcheck with brew."
    brew update
    brew install shellcheck
}

if command -v apt-get >/dev/null 2>&1; then
    install_with_apt
elif command -v dnf >/dev/null 2>&1; then
    install_with_dnf
elif command -v yum >/dev/null 2>&1; then
    install_with_yum
elif command -v pacman >/dev/null 2>&1; then
    install_with_pacman
elif command -v zypper >/dev/null 2>&1; then
    install_with_zypper
elif command -v apk >/dev/null 2>&1; then
    install_with_apk
elif command -v brew >/dev/null 2>&1; then
    install_with_brew
else
    log "Unable to detect a supported package manager. Please install shellcheck manually from https://www.shellcheck.net/ and rerun this script."
    exit 1
fi

if command -v shellcheck >/dev/null 2>&1; then
    log "ShellCheck installation completed successfully at $(command -v shellcheck)."
else
    log "Installation process finished but shellcheck is still not available on PATH."
    exit 1
fi
