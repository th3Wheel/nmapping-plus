#!/usr/bin/env bash
# pihole_health_logger.sh
# Runs check_pihole_metrics.sh and appends output to a log file with rotation helper.

set -euo pipefail

LOGFILE=/var/log/pihole-health.log
TMPFILE=$(mktemp)

if [[ ! -x "$(pwd)/check_pihole_metrics.sh" ]]; then
  echo "check_pihole_metrics.sh not found or not executable in current directory" >&2
  exit 2
fi

./check_pihole_metrics.sh > "$TMPFILE"
jq . "$TMPFILE" >> "$LOGFILE" 2>/dev/null || cat "$TMPFILE" >> "$LOGFILE"
rm -f "$TMPFILE"

# Trim log to last 10000 lines
tail -n 10000 "$LOGFILE" > "$LOGFILE.tmp" && mv "$LOGFILE.tmp" "$LOGFILE"

exit 0
