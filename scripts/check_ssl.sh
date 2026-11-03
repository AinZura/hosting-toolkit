#!/usr/bin/env bash
# check_ssl.sh - report when a domain's SSL certificate expires
# Usage: ./check_ssl.sh domain [port] [warn_days] [crit_days]
# Exit codes: 0 = OK, 1 = WARNING, 2 = CRITICAL, 3 = UNKNOWN (no certificate)

DOMAIN=$1
PORT=${2:-443}
WARN=${3:-30}
CRIT=${4:-14}

if [ -z "$DOMAIN" ]; then
  echo "Usage: $0 domain [port] [warn_days] [crit_days]"
  exit 3
fi

# echo | closes stdin so openssl exits; timeout stops a hang on dead hosts
cert=$(echo | timeout 10 openssl s_client -servername "$DOMAIN" -connect "$DOMAIN:$PORT" 2>/dev/null \
  | openssl x509 -noout -enddate -issuer 2>/dev/null)

if [ -z "$cert" ]; then
  echo "UNKNOWN: could not read a certificate from $DOMAIN:$PORT"
  exit 3
fi

end_date=$(echo "$cert" | sed -n 's/^notAfter=//p')
issuer=$(echo "$cert" | sed -n 's/^issuer=//p')
days_left=$(( ( $(date -d "$end_date" +%s) - $(date +%s) ) / 86400 ))

if [ "$days_left" -lt "$CRIT" ]; then
  level="CRITICAL"; code=2
elif [ "$days_left" -lt "$WARN" ]; then
  level="WARNING"; code=1
else
  level="OK"; code=0
fi

echo "$level: $DOMAIN expires in $days_left days ($end_date)"
echo "Issuer: $issuer"
exit "$code"