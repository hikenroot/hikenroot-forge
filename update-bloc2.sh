#!/bin/bash
set -e
BLOC2="docs/labs/identity-lab/bloc2-entra-hybrid"
cd ~/hikenroot-forge

# SC-ID-010
sed -i '/^## Auteur\|^## Correspondance/i\
### Preuves\
\
![Overview du tenant — Entra ID Premium P2, Entra Connect activé](assets/SC-ID-010-01-tenant-overview.png)\
\
![Comptes Break Glass — BG01 et BG02](assets/SC-ID-010-02-breakglass-accounts.png)\
\
![BG01 — Administrateur général, affectation active](assets/SC-ID-010-03-bg01-roles.png)\
\
![BG02 — Administrateur général, affectation active](assets/SC-ID-010-04-bg02-roles.png)\
\
![Licences — Entra ID P1 et P2 actives](assets/SC-ID-010-05-license-p2.png)\
\
---\
' "$BLOC2/SC-ID-010-tenant-breakglass.md"
echo "✅ SC-ID-010 mis à jour"

# SC-ID-011
sed -i '/^## Auteur\|^## Correspondance/i\
### Preuves\
\
![VM ADCONNECT sur Proxmox — VMID 111](assets/SC-ID-011-01-proxmox-vm.png)\
\
![Configuration Terraform — main.tf](assets/SC-ID-011-02-terraform-config.png)\
\
![Console AD Connect sur ADCONNECT](assets/SC-ID-011-03-adconnect-console.png)\
\
---\
' "$BLOC2/SC-ID-011-vm-adconnect.md"
echo "✅ SC-ID-011 mis à jour"

# SC-ID-012
sed -i '/^## Auteur\|^## Correspondance/i\
### Preuves\
\
![Synchronization Service — statut des runs](assets/SC-ID-012-01-sync-status.png)\
\
![Connectors — 2 forêts + Entra ID](assets/SC-ID-012-02-connectors.png)\
\
![Utilisateurs synchronisés dans Entra](assets/SC-ID-012-03-synced-users.png)\
\
![Features AD Connect — PHS, SSO, Writeback](assets/SC-ID-012-04-features.png)\
\
![Filtrage OU — exclusion Tier0, Domain Controllers, Builtin](assets/SC-ID-012-05-ou-filtering.png)\
\
---\
' "$BLOC2/SC-ID-012-adconnect-hybrid.md"
echo "✅ SC-ID-012 mis à jour"

# SC-ID-013
sed -i '/^## Auteur\|^## Correspondance/i\
### Preuves\
\
![4 Conditional Access policies en Report-only](assets/SC-ID-013-01-ca-policies-list.png)\
\
![CA001 — Block Legacy Authentication](assets/SC-ID-013-02-ca001-detail.png)\
\
![CA002 — MFA pour les Admins](assets/SC-ID-013-03-ca002-detail.png)\
\
![Named Location — Blocked-Countries](assets/SC-ID-013-04-named-location.png)\
\
---\
' "$BLOC2/SC-ID-013-conditional-access.md"
echo "✅ SC-ID-013 mis à jour"

# SC-ID-014
sed -i '/^## Auteur\|^## Correspondance/i\
### Preuves\
\
![PIM — Paramètres Global Admin (4h max, MFA, justification, approbation)](assets/SC-ID-014-01-pim-settings.png)\
\
![Affectations éligibles — admin + hiken root](assets/SC-ID-014-02-eligible-assignments.png)\
\
![Affectations actives — BG01 + BG02 permanent](assets/SC-ID-014-03-active-assignments.png)\
\
---\
' "$BLOC2/SC-ID-014-pim.md"
echo "✅ SC-ID-014 mis à jour"

echo ""
echo "=== Bloc 2 — Tous les write-ups mis à jour ==="
grep -c "assets/" $BLOC2/SC-ID-*.md | while read line; do
  echo "  $line screenshot(s)"
done
