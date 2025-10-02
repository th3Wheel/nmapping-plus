#!/usr/bin/env bash
# check_pihole_metrics.sh
# Outputs simple JSON metrics for Pi-hole health checks.

set -euo pipefail

timestamp() {
  date --utc +"%Y-%m-%dT%H:%M:%SZ"
}

# DNS check
dig @127.0.0.1 pi.hole +short >/dev/null 2>&1
dns_ok=$?

# FTL process check
if pgrep pihole-FTL >/dev/null 2>&1; then
  ftl_ok=0
else
  ftl_ok=1
fi

# Web UI check
if curl -sS --connect-timeout 2 http://127.0.0.1/admin/ >/dev/null 2>&1; then
  ui_ok=0
else
  ui_ok=1
fi

cat <<EOF
{
  "timestamp": "$(timestamp)",
  "dns": $dns_ok,
  "ftl": $ftl_ok,
  "ui": $ui_ok
}
EOF

exit 0
