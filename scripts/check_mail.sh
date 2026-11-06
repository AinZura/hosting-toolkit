#!/usr/bin/env bash
# check_mail.sh - check the DNS records a domain needs to send and receive mail
# Usage: ./check_mail.sh domain [dkim_selector]
# Exit codes: 0 = all OK, 1 = WARN, 2 = MISSING, 3 = UNKNOWN (no dig, no domain, or no resolver reply)

DOMAIN=$1
SELECTOR=$2

if [ -z "$DOMAIN" ]; then
  echo "Usage: $0 domain [dkim_selector]"
  exit 3
fi

# Without dig every check below would report a false MISSING
if ! command -v dig >/dev/null 2>&1; then
  echo "UNKNOWN: dig is not installed (Debian/Ubuntu: apt install dnsutils)"
  exit 3
fi

status=0

# Run dig and store the answer in $answer. dig exits non-zero when the
# resolver never replies; that is UNKNOWN, not MISSING, so stop with exit 3.
lookup() {
  answer=$(dig +short +time=5 +tries=2 "$@" 2>/dev/null)
  rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "UNKNOWN: DNS lookup for $2 failed (dig exit $rc, resolver not reachable)"
    exit 3
  fi
}

# Print one result row and remember the worst status seen: OK < WARN < MISSING
row() {
  printf '%-8s %-8s %s\n' "$1" "$2" "$3"
  case "$2" in
    WARN)    if [ "$status" -lt 1 ]; then status=1; fi ;;
    MISSING) status=2 ;;
  esac
}

printf '%-8s %-8s %s\n' "CHECK" "STATUS" "DETAIL"

# MX: where incoming mail is delivered. No MX means no mail can arrive;
# a single MX works but has no backup if that server is down.
lookup MX "$DOMAIN"
mx=$answer
mx_count=$(printf '%s\n' "$mx" | grep -c .)

if [ "$mx_count" -eq 0 ]; then
  row MX MISSING "no MX records"
elif printf '%s\n' "$mx" | grep -q '[[:space:]]\.$'; then
  row MX MISSING "null MX: domain declares it accepts no mail"
elif [ "$mx_count" -eq 1 ]; then
  row MX WARN "only one MX: $(printf '%s\n' "$mx" | awk '{print $2}') (no backup)"
else
  row MX OK "$(printf '%s\n' "$mx" | awk '{print $2}' | tr '\n' ' ' | sed 's/ $//')"
fi

# SPF: a TXT record starting with v=spf1 lists the servers allowed to send
# mail for the domain. There must be exactly one, and it should end in -all
# or ~all so everyone else is rejected.
lookup TXT "$DOMAIN"
txt=$answer
spf=$(printf '%s\n' "$txt" | tr -d '"' | grep -i '^v=spf1')
spf_count=$(printf '%s\n' "$spf" | grep -c .)

if [ "$spf_count" -eq 0 ]; then
  row SPF MISSING "no TXT record starting with v=spf1"
elif [ "$spf_count" -gt 1 ]; then
  row SPF WARN "multiple SPF records; the spec allows only one"
else
  all=$(printf '%s\n' "$spf" | awk '{print $NF}' | tr '[:upper:]' '[:lower:]')
  case "$all" in
    -all|~all|redirect=*) row SPF OK "$spf" ;;
    +all|all|"")          row SPF WARN "$spf (allows any sender; use -all or ~all)" ;;
    *)                    row SPF WARN "$spf (no all mechanism, defaults to neutral)" ;;
  esac
fi

# DMARC: a TXT record at _dmarc.<domain> tells receivers what to do with mail
# that fails SPF/DKIM. p=none only monitors; p=quarantine or p=reject enforces.
lookup TXT "_dmarc.$DOMAIN"
dmarc=$(printf '%s\n' "$answer" | tr -d '"' | grep -i '^v=DMARC1')
dmarc_count=$(printf '%s\n' "$dmarc" | grep -c .)

if [ "$dmarc_count" -eq 0 ]; then
  row DMARC MISSING "no TXT record at _dmarc.$DOMAIN"
elif [ "$dmarc_count" -gt 1 ]; then
  row DMARC WARN "multiple DMARC records; the spec allows only one"
else
  # Take the p= tag from the semicolon-separated list (not sp= or adkim=)
  policy=$(printf '%s\n' "$dmarc" | tr ';' '\n' \
    | sed -n 's/^[[:space:]]*p=\([A-Za-z]*\).*/\1/p' | head -n 1 | tr '[:upper:]' '[:lower:]')
  case "$policy" in
    quarantine|reject) row DMARC OK "$dmarc" ;;
    none)              row DMARC WARN "$dmarc (p=none: monitoring only)" ;;
    "")                row DMARC WARN "$dmarc (no p= policy tag)" ;;
    *)                 row DMARC WARN "$dmarc (unknown policy p=$policy)" ;;
  esac
fi

# DKIM: the public key is a TXT record at <selector>._domainkey.<domain>.
# The selector is chosen by the mail setup, so this check only runs when the
# caller passes one as the second argument.
if [ -n "$SELECTOR" ]; then
  dkim_name="$SELECTOR._domainkey.$DOMAIN"
  lookup TXT "$dkim_name"
  dkim=$(printf '%s\n' "$answer" | tr -d '"')

  if [ -z "$dkim" ]; then
    row DKIM MISSING "no TXT record at $dkim_name"
  elif printf '%s\n' "$dkim" | grep -qE 'p=[[:space:]]*(;|$)'; then
    row DKIM WARN "key is empty (revoked) at $dkim_name"
  elif ! printf '%s\n' "$dkim" | grep -qi 'p='; then
    row DKIM WARN "no p= public key at $dkim_name"
  else
    row DKIM OK "key found at $dkim_name"
  fi
fi

exit "$status"
