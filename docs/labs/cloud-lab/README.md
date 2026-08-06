# Cloud Lab — Write-ups Index
## HikenRoot Forge | MediaTech Groupe SA

Exploitation scenarios against **Kubernetes Goat** (cluster Kubernetes volontairement vulnérable), déployé sur un cluster K3s 3 nœuds (VLAN 30). Chaque write-up suit le format de livrable pentest standard : kill chain, CVSS, MITRE ATT&CK, impact métier (COMEX), détection SOC, remédiation.

> **Contexte MediaTech** : la plateforme numérique du groupe (paywall d'abonnement, applis mobiles, API de contenu) tourne en cloud-native. Ces scénarios touchent donc directement le CA récurrent, pas un simple lab.

---

## Progression

| Scénario | Technique | Cible | Sévérité | CVSS | Statut |
|----------|-----------|-------|----------|------|--------|
| [SC-CLD-001](SC-CLD-001-sensitive-keys-in-codebases.md) | Sensitive Keys in Codebases | `build-code-service` → image Docker avec `.git` | 🔴 Critique | 9.1 | Done |
| [SC-CLD-002](SC-CLD-002-ssrf-in-the-kubernetes-world.md) | SSRF → Metadata cluster | `internal-proxy-info-app` → `metadata-db` | 🔴 Critique | 9.3 | Done |
| [SC-CLD-003](SC-CLD-003-container-escape-to-host-system.md) | Container Escape to Host | `system-monitor` pod → worker node | 🔴 Critique | 9.8 | Done |
| [SC-CLD-004](SC-CLD-004-rbac-least-privileges-misconfiguration.md) | RBAC Misconfiguration | `hunger-check` pod → secrets `big-monolith` | 🟠 Élevée | 8.8 | Done |
| [SC-CLD-005](SC-CLD-005-attacking-private-registry.md) | Attacking Private Registry | `poor-registry-service` → Docker Registry v2 | 🔴 Critique | 9.8 | Done |

---

## Write-up Format

Chaque scénario inclut :

- Classification : CVSS 3.1, cible, flag Kubernetes Goat
- Résumé exécutif : recruteur / auditeur ISO 27001 / RSSI
- Kill chain (Mermaid)
- Exploitation pas à pas avec commandes et sorties réelles
- Détection SOC : signaux, règles
- Impact métier — MediaTech Groupe SA : estimation financière, mapping RGPD/NIS2/ISO 27001, décisions COMEX
- Remédiation : secure-by-design + architecture cible

---

## Infrastructure Reference

| Élément | Détail |
|---------|--------|
| Plateforme | Kubernetes Goat (volontairement vulnérable) |
| Cluster | K3s — 3 nœuds (1 master + 2 workers) |
| VLAN | 30 — Lab Cloud (192.168.30.0/24) |
| Registry | `poor-registry-service` — Docker Registry v2 sans authentification |
| Namespace notable | `big-monolith` (secrets applicatifs) |

> ⚠️ Les clés AWS et les flags présents dans ces write-ups sont des **artefacts CTF de Kubernetes Goat** (lab volontairement vulnérable) — **pas des secrets réels**.

---

## References

- [Index général HikenRoot Forge](../../README_FR.md)
- Kubernetes Goat : https://github.com/madhuakula/kubernetes-goat
- OWASP Kubernetes Top 10 : https://owasp.org/www-project-kubernetes-top-ten/
- HackTricks Cloud : https://cloud.hacktricks.xyz

---

*Auteur : hik3nR00t | HikenRoot Forge | Août 2026*
