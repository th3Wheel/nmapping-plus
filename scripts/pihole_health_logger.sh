#!/usr/bin/env bash
# pihole_health_logger.sh
# Runs check_pihole_metrics.sh and appends output to a log file with rotation helper.

set -euo pipefail

LOGFILE=/var/log/pihole-health.log
ERROR_LOG=/var/log/pihole-health-error.log
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK_SCRIPT="$SCRIPT_DIR/check_pihole_metrics.sh"
if [[ ! -x "$CHECK_SCRIPT" ]]; then
  echo "check_pihole_metrics.sh not found or not executable in $SCRIPT_DIR" >&2
  exit 2
fi

# Ensure log files exist
touch "$LOGFILE" "$ERROR_LOG" 2>/dev/null || {
  echo "Error: Cannot create or write to log files" >&2
  exit 1
}

"$CHECK_SCRIPT" > "$TMPFILE"

# Validate JSON output
if ! jq . "$TMPFILE" > /dev/null 2>&1; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') - Invalid JSON output from check_pihole_metrics.sh" >> "$ERROR_LOG"
  echo "$(date '+%Y-%m-%d %H:%M:%S') - Raw output:" >> "$ERROR_LOG"
  cat "$TMPFILE" >> "$ERROR_LOG"
  exit 1
fi

# Append valid JSON to log with error handling
if ! jq . "$TMPFILE" >> "$LOGFILE" 2>/dev/null; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') - Failed to write to $LOGFILE (jq filter error)" >> "$ERROR_LOG"
  exit 1
fi
if jq . "$TMPFILE" > /dev/null 2>&1; then
# TMPFILE cleanup handled by trap on EXIT
else
  echo "$(date '+%Y-%m-%d %H:%M:%S') - Invalid JSON output from check_pihole_metrics.sh" >> /var/log/pihole-health-error.log
fi
jq . "$TMPFILE" >> "$LOGFILE" 2>/dev/null || cat "$TMPFILE" >> "$LOGFILE"
rm -f "$TMPFILE"

# Trim log to last 10000 lines
if [[ -f "$LOGFILE" ]]; then
  tail -n 10000 "$LOGFILE" > "$LOGFILE.tmp" && mv "$LOGFILE.tmp" "$LOGFILE" || {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Failed to rotate log file" >> "$ERROR_LOG"
    exit 1
  }
fi

exit 0
