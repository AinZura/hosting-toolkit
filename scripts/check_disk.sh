#!/usr/bin/env bash
# check_disk.sh - warn when a mounted filesystem is getting full
# Usage: ./check_disk.sh [warn_percent] [crit_percent]
# Exit codes: 0 = OK, 1 = WARNING, 2 = CRITICAL

WARN=${1:-80}
CRIT=${2:-90}
status=0

printf '%-25s %-8s %s\n' "MOUNT" "USED" "STATUS"

while read -r mount pct; do
  pct=${pct%\%}
  if [ "$pct" -ge "$CRIT" ]; then
    level="CRITICAL"
    [ "$status" -lt 2 ] && status=2
  elif [ "$pct" -ge "$WARN" ]; then
    level="WARNING"
    [ "$status" -lt 1 ] && status=1
  else
    level="OK"
  fi
  printf '%-25s %-8s %s\n' "$mount" "${pct}%" "$level"
done < <(df --output=target,pcent -x tmpfs -x devtmpfs -x squashfs -x overlay | tail -n +2)

exit "$status"