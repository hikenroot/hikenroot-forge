#!/bin/bash
# =============================================================
# Script de mise à jour des write-ups Bloc 1 avec screenshots
# À exécuter depuis ~/hikenroot-forge sur WSL
# =============================================================
set -e
BLOC1="docs/labs/identity-lab/bloc1-ad-onprem"

echo "=== Mise à jour des write-ups avec screenshots ==="

# -------------------------------------------------------
# SC-ID-001 — Ajout screenshots après les sections clés
# -------------------------------------------------------
cd ~/hikenroot-forge

# Insérer après "## Architecture découverte" -> avant le mermaid
sed -i '/^## Étape 1 — Découverte réseau/i\
### Preuves — Forêts et Domaines\
\
![Vue ADUC — Forêt sevenkingdoms.local](assets/SC-ID-001-01-forest-sevenkingdoms.png)\
\
![Sortie Get-ADForest](assets/SC-ID-001-04-get-adforest.png)\
\
![Sortie Get-ADDomain — sevenkingdoms.local](assets/SC-ID-001-05-get-addomain-sevenkingdoms.png)\
\
![Structure des OUs — arborescence complète](assets/SC-ID-001-08-ou-structure.png)\
\
### Preuves — Relations d'\''approbation (Trusts)\
\
![Relations de trust — sevenkingdoms.local (Forest + Child)](assets/SC-ID-001-03-trusts-overview.png)\
\
![Trust north.sevenkingdoms.local — Parent bidirectionnel](assets/SC-ID-001-03b-trusts-north.png)\
\
![Sortie Get-ADTrust -Filter *](assets/SC-ID-001-07-get-adtrust.png)\
\
---\
' "$BLOC1/SC-ID-001-cartographie-ad.md"

echo "✅ SC-ID-001 mis à jour"

# -------------------------------------------------------
# SC-ID-002 — Ajout screenshots
# -------------------------------------------------------
sed -i '/^## Étape 1 — Vue globale/i\
### Preuves — Réplication\
\
![repadmin /replsummary — vue synthétique](assets/SC-ID-002-01-replsummary.png)\
\
![repadmin /showrepl — DC01 KINGSLANDING](assets/SC-ID-002-02-showrepl-dc01.png)\
\
![repadmin /showrepl — DC02 WINTERFELL](assets/SC-ID-002-03-showrepl-dc02.png)\
\
![repadmin /showrepl — DC03 MEEREEN](assets/SC-ID-002-04-showrepl-dc03.png)\
\
![dcdiag /test:replications — validation](assets/SC-ID-002-05-dcdiag-repl.png)\
\
![Connexions de réplication — AD Sites \& Services](assets/SC-ID-002-06-repl-connections.png)\
\
---\
' "$BLOC1/SC-ID-002-sante-replication.md"

echo "✅ SC-ID-002 mis à jour"

# -------------------------------------------------------
# SC-ID-003 — Ajout screenshots
# -------------------------------------------------------
sed -i '/^## Implémentation/i\
### Preuves — Sites \& Services\
\
![Vue globale des sites AD — subnets et site links](assets/SC-ID-003-01-sites-overview.png)\
\
![Site Links — Paris-Essos (500/60min) et Paris-Nord (100/15min)](assets/SC-ID-003-03-sitelinks.png)\
\
![Propriétés du Site Link Paris-Nord — coût et intervalle](assets/SC-ID-003-05-sitelink-properties.png)\
\
---\
' "$BLOC1/SC-ID-003-sites-services.md"

echo "✅ SC-ID-003 mis à jour"

# -------------------------------------------------------
# SC-ID-004 — Ajout screenshots
# -------------------------------------------------------
sed -i '/^## Implémentation/i\
### Preuves — Implémentation du Tiering\
\
![Structure OUs Tiering dans ADUC](assets/SC-ID-004-01-tiering-ou-structure.png)\
\
![GPOs de tiering liées aux OUs — GPMC](assets/SC-ID-004-02-tiering-gpos-linked.png)\
\
![Groupes et comptes Tier 0](assets/SC-ID-004-03-tier0-groups.png)\
\
![GPO Deny Logon — restriction cross-tier](assets/SC-ID-004-04-deny-logon-gpo.png)\
\
![Membres du groupe Tier 0 Admins](assets/SC-ID-004-05-t0-admin-members.png)\
\
---\
' "$BLOC1/SC-ID-004-tiering-model.md"

echo "✅ SC-ID-004 mis à jour"

# -------------------------------------------------------
# SC-ID-005 — Ajout screenshots
# -------------------------------------------------------
sed -i '/^## Exécution/i\
### Preuves — Audit PingCastle Initial\
\
![Score global — 57/100 avant hardening](assets/SC-ID-005-01-score-global-before.png)\
\
![Radar chart — 4 catégories (Stale 26, Privileged 50, Trusts 51, Anomalies 57)](assets/SC-ID-005-02-radar-before.png)\
\
![Risk Model — matrice des risques par catégorie](assets/SC-ID-005-03-top-risks.png)\
\
![Exécution PingCastle — ligne de commande](assets/SC-ID-005-05-cli-execution.png)\
\
---\
' "$BLOC1/SC-ID-005-pingcastle-audit.md"

echo "✅ SC-ID-005 mis à jour"

# -------------------------------------------------------
# SC-ID-006 — Ajout screenshots
# -------------------------------------------------------
sed -i '/^## Chemins d'\''attaque identifiés/i\
### Preuves — BloodHound\
\
![Statistiques du domaine — 35 users, 116 groups, 6 computers](assets/SC-ID-006-07-domain-stats.png)\
\
![Shortest Path to Domain Admin](assets/SC-ID-006-03-path-to-da.png)\
\
![Utilisateurs Kerberoastable](assets/SC-ID-006-04-kerberoastable.png)\
\
![Utilisateurs AS-REP Roastable](assets/SC-ID-006-05-asrep-roastable.png)\
\
![Unconstrained Delegation — WINTERFELL et MEEREEN](assets/SC-ID-006-06-unconstrained-deleg.png)\
\
---\
' "$BLOC1/SC-ID-006-bloodhound.md"

echo "✅ SC-ID-006 mis à jour"

# -------------------------------------------------------
# SC-ID-008 — Ajout screenshots
# -------------------------------------------------------
sed -i '/^## Remédiation 1 — Rotation krbtgt/i\
### Preuves — État Kerberos\
\
![krbtgt — Created 03/12/2025, PasswordLastSet 23/03/2026](assets/SC-ID-008-01-krbtgt-before.png)\
\
![SPN — seul krbtgt avec kadmin/changepw (natif)](assets/SC-ID-008-04-spn-cleanup.png)\
\
![Pre-Auth — aucun compte vulnérable (remédiation effectuée)](assets/SC-ID-008-05-preauth-before.png)\
\
![Unconstrained Delegation — KINGSLANDING uniquement (PDC)](assets/SC-ID-008-07-delegation-review.png)\
\
---\
' "$BLOC1/SC-ID-008-remediation-kerberos.md"

echo "✅ SC-ID-008 mis à jour"

# -------------------------------------------------------
# SC-ID-009 — Ajout screenshots
# -------------------------------------------------------
sed -i '/^## Pourquoi le score reste à 85/i\
### Preuves — PingCastle Post-Hardening\
\
![Score global post-hardening — 85/100](assets/SC-ID-009-01-score-global-after.png)\
\
![Radar chart post-hardening — Anomalies passé de 72 à 62](assets/SC-ID-009-02-radar-after.png)\
\
---\
' "$BLOC1/SC-ID-009-pingcastle-post-hardening.md"

echo "✅ SC-ID-009 mis à jour"

echo ""
echo "=== Tous les write-ups sont mis à jour ==="
echo ""
echo "Vérification :"
grep -c "assets/" $BLOC1/SC-ID-*.md | while read line; do
  echo "  $line screenshot(s)"
done
