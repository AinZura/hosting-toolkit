#!/usr/bin/env python3
"""dns_check.py - show the main DNS records for a domain.

Usage: python scripts/dns_check.py example.com [--server 8.8.8.8]
Exit codes: 0 = records found, 1 = no records, 2 = domain does not exist
"""
import argparse
import sys

import dns.exception
import dns.resolver

RECORD_TYPES = ["A", "AAAA", "CNAME", "MX", "NS", "TXT"]


def lookup(resolver, domain, rtype):
    """Return a sorted list of record strings, or [] if there are none."""
    try:
        answers = resolver.resolve(domain, rtype)
    except dns.resolver.NoAnswer:
        return []
    except dns.exception.Timeout:
        return ["<timeout>"]
    except dns.resolver.NoNameservers:
        return ["<lookup failed>"]
    return sorted(r.to_text() for r in answers)


def main():
    parser = argparse.ArgumentParser(description="Show DNS records for a domain")
    parser.add_argument("domain")
    parser.add_argument("--server", help="DNS server to ask, e.g. 8.8.8.8")
    args = parser.parse_args()

    resolver = dns.resolver.Resolver()
    resolver.lifetime = 5
    if args.server:
        resolver.nameservers = [args.server]

    print(f"DNS records for {args.domain}")
    found_any = False
    for rtype in RECORD_TYPES:
        try:
            records = lookup(resolver, args.domain, rtype)
        except dns.resolver.NXDOMAIN:
            print(f"ERROR: {args.domain} does not exist (NXDOMAIN)")
            return 2
        for record in records:
            found_any = True
            print(f"{rtype:<6} {record}")

    return 0 if found_any else 1


if __name__ == "__main__":
    sys.exit(main())
    