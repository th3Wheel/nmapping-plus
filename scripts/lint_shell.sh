#!/usr/bin/env bash
# lint_shell.sh -- Run ShellCheck across repository shell scripts with consistent reporting.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIRS=("$ROOT_DIR/scripts" "${ROOT_DIR}/dashboard" "${ROOT_DIR}/docs")
EXCLUDE_PATTERNS=()

# Add Windows-specific paths only if running on Windows
case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*)
        CHOCO_BIN="/c/ProgramData/chocolatey/bin"
        SCOOP_BIN="/c/Users/${USERNAME:-${USER:-}}/scoop/shims"
        WINGET_BIN="/c/Program Files/WindowsApps"
        for extra_path in "$CHOCO_BIN" "$SCOOP_BIN" "$WINGET_BIN"; do
            if [ -d "$extra_path" ] && [[ ":$PATH:" != *":$extra_path:"* ]]; then
                PATH="$PATH:$extra_path"
            fi
        done
        export PATH
        ;;
    *)
        # Non-Windows: do not modify PATH for Windows-specific tools
        ;;
esac

if ! command -v shellcheck >/dev/null 2>&1; then
    cat <<'EOF' >&2
ShellCheck is required but not available on PATH.
Use scripts/install_shellcheck.sh or scripts/install_shellcheck.ps1 to install it, then rerun this lint.
EOF
    exit 1
fi

log() {
    printf '[Shell Lint] %s\n' "$1"
}

collect_scripts() {
    local dir="$1"
    find "$dir" -type f \( -name '*.sh' -o -name '*.bash' -o -name '*.ksh' \) 2>/dev/null || true
}

mapfile -t raw_scripts < <(
    for dir in "${SCRIPTS_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            collect_scripts "$dir"
        fi
    done | sort -u
)

scripts=()
skipped=()

for script in "${raw_scripts[@]}"; do
    skip=false
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        if [[ "$script" == *"$pattern"* ]]; then
            skip=true
            skipped+=("$script")
            break
        fi
    done
    if [ "$skip" = false ]; then
        scripts+=("$script")
    fi
done

for script in "${skipped[@]}"; do
    log "Skipping $script (temporarily excluded from lint)."
done

if [ "${#scripts[@]}" -eq 0 ]; then
    log "No shell scripts found to lint."
    exit 0
fi

log "Running ShellCheck on ${#scripts[@]} script(s)..."

failed=0
for script in "${scripts[@]}"; do
    log "Checking $script"
    if ! shellcheck "$script"; then
        failed=1
    fi
done

if [ "$failed" -ne 0 ]; then
    log "ShellCheck reported issues."
    exit 1
fi

log "ShellCheck completed without errors."
