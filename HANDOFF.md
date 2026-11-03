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
