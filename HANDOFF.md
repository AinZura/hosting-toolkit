# Handoff context

## Goal
One-month job hunt for entry-level Linux/hosting support (L1/L2); secondary: junior backend/applied AI.
Build order: hosting-toolkit -> server-automation (Ansible) -> health-monitor (FastAPI) -> rag-helpdesk. Resume/LinkedIn/portfolio site come last.

## Environment
- Windows laptop, WSL2 Ubuntu 24.04. Projects live in ~/projects (Linux side only).
- Practice VPS: DigitalOcean, Ubuntu 24.04, 512 MB RAM + 1 GB swap. User `hans`, SSH key-only, root login off, ufw allows OpenSSH only.

## Conventions
- Scripts live in scripts/. Exit codes: 0 OK, 1 WARNING, 2 CRITICAL, 3 UNKNOWN.
- Thresholds are optional arguments with defaults.
- Python uses a venv (.venv, not committed); dependencies are in requirements.txt.

## How I work
- I'm a novice-to-intermediate developer. Explain each step and each line.
- I must be able to explain all code. I write runbook.md and eval questions myself.
- Never put keys or secrets in the repo.

## Done
- Day 1: environment, VPS hardening, check_disk.sh, check_memory.sh
- Day 2: check_ssl.sh, dns_check.py

## Planned scripts
- scripts/check_mail.sh: MX, SPF, DMARC, optional DKIM selector, using dig. OK/WARN/MISSING per check.
- scripts/tail_errors.sh: scan web server logs for 5xx responses and PHP fatal errors across vhosts.
- scripts/report.py: run all checks and print a one-page diagnostic.
- main.py: argparse CLI that wraps the scripts.
- runbook.md: 10 hosting issues (symptom, diagnosis, fix, prevention). Written by me, not AI.

## Standing rules for the agent
After every task, end your reply with a "How I can verify this myself" section:
1. Exact commands to run, in order, from the repo root, each with the expected output.
2. At least one failure-case test with the expected exit code.
3. A short list explaining every non-obvious line or pattern (regex, parameter
   expansion, process substitution, etc.) in plain English: "pattern -> what it does".
4. What you did NOT test, what you assumed, and anything you stubbed or mocked.
Never claim a test passed unless you ran it. I am studying and must be able to
explain all of this code in an interview, so keep explanations short and concrete.
Do not add complexity beyond what I asked for. List suggestions separately and wait.

## Known limitations
- check_mail.sh: a SERVFAIL response (for example broken DNSSEC) shows as MISSING, not UNKNOWN.
