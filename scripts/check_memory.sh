#!/usr/bin/env bash
# check_memory.sh - report RAM and swap usage
# Usage: ./check_memory.sh [warn_percent] [crit_percent]
# Exit codes: 0 = OK, 1 = WARNING, 2 = CRITICAL (based on RAM)

WARN=${1:-80}
CRIT=${2:-90}

# Values in /proc/meminfo are in kB
read -r total avail < <(awk '/^MemTotal/ {t=$2} /^MemAvailable/ {a=$2} END {print t, a}' /proc/meminfo)
read -r swap_total swap_free < <(awk '/^SwapTotal/ {t=$2} /^SwapFree/ {f=$2} END {print t, f}' /proc/meminfo)

used=$(( total - avail ))
pct=$(( used * 100 / total ))

if [ "$pct" -ge "$CRIT" ]; then
  level="CRITICAL"; code=2
elif [ "$pct" -ge "$WARN" ]; then
  level="WARNING"; code=1
else
  level="OK"; code=0
fi

echo "RAM:  $(( used / 1024 )) MB used of $(( total / 1024 )) MB (${pct}%) - $level"

if [ "$swap_total" -gt 0 ]; then
  swap_used=$(( swap_total - swap_free ))
  echo "Swap: $(( swap_used / 1024 )) MB used of $(( swap_total / 1024 )) MB"
else
  echo "Swap: none configured"
fi

exit "$code"
