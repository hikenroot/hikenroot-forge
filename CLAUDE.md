# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

HikenRoot Forge is a cybersecurity training lab documentation repository. It contains no application code, build system, or tests. The repo is entirely documentation: write-ups, architecture docs, IaC config placeholders, and Mermaid diagrams — all centered around **MediaTech Groupe SA**, a fictional enterprise used as business context for every scenario.

## Structure

- `docs/labs/ad-lab/SC-AD-*.md` — Active Directory attack write-ups (12 scenarios, GOAD v3)
- `docs/labs/cloud-lab/SC-CLD-*.md` — Cloud/Kubernetes attack write-ups (6 scenarios)
- `docs/goad/` — GOAD infrastructure docs (HLD, WireGuard, backup, troubleshooting)
- `diagrams/` — Mermaid-based architecture and network topology diagrams
- `configs/` — Placeholder dirs for pfSense, Proxmox, Kubernetes, Docker configs
- `scripts/` — Placeholder dirs for backup and deploy scripts
- `docs/README_FR.md` — French translation of the main README

## Write-up Format

Every scenario write-up follows this exact structure — maintain it when creating or editing:

1. Classification (severity, CVSS 3.1, affected systems)
2. Executive Summary (recruiter/auditor/CISO audience)
3. Kill Chain (Mermaid diagram)
4. Exploitation (step-by-step with commands and outputs)
5. Business Impact — MediaTech Groupe SA (financial estimation, risk matrix, GDPR/NIS2/ISO 27001, COMEX decisions)
6. Detection (Event IDs, Sigma rules, IOCs)
7. Remediation — Secure by Design (0-24h / 1 week / 1 month)
8. Target Architecture (Mermaid diagram)

## Conventions

- Bilingual repo: README exists in EN (`README.md`) and FR (`docs/README_FR.md`). Keep both in sync.
- Scenario IDs: `SC-AD-NNN` for AD lab, `SC-CLD-NNN` for cloud lab. Future: `SC-FIN`, `SC-JUR`, `SC-IT`, `SC-SUP`, `SC-USR`.
- Diagrams use Mermaid syntax embedded in Markdown.
- The `.gitignore` aggressively excludes secrets (*.key, *.pem, *.env, wg*.conf), VM images, Terraform state, and kubeconfigs. Never commit these.
- Network: VLAN 10 = AD Lab, VLAN 20 = Web Lab, VLAN 30 = Cloud Lab, VLAN 40 = AI Lab, VLAN 50 = Management.

## Project Status

- Phase 1 (Infrastructure + AD/Cloud write-ups): Complete
- Phase 2 (Cloud + AI + SOC + Guacamole): In progress
- Phase 3 (DFIR + OT/ICS + Mobile): Planned
- Phase 4 (GitBook documentation FR/EN): Planned
