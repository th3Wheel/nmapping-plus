#!/usr/bin/env bash
# pihole_health_logger.sh
# Runs check_pihole_metrics.sh and appends output to a log file with rotation helper.

set -euo pipefail

LOGFILE=/var/log/pihole-health.log
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK_SCRIPT="$SCRIPT_DIR/check_pihole_metrics.sh"
if [[ ! -x "$CHECK_SCRIPT" ]]; then
  echo "check_pihole_metrics.sh not found or not executable in $SCRIPT_DIR" >&2
  exit 2
fi

"$CHECK_SCRIPT" > "$TMPFILE"
if jq . "$TMPFILE" > /dev/null 2>&1; then
# TMPFILE cleanup handled by trap on EXIT
else
  echo "$(date '+%Y-%m-%d %H:%M:%S') - Invalid JSON output from check_pihole_metrics.sh" >> /var/log/pihole-health-error.log
fi
rm -f "$TMPFILE"

# Trim log to last 10000 lines
tail -n 10000 "$LOGFILE" > "$LOGFILE.tmp" && mv "$LOGFILE.tmp" "$LOGFILE"

exit 0
