#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/src/incident_handoff_runbook.sh"

REPORT_DIR="${ROOT_DIR}/site/.generated"
REPORT_FILE="${REPORT_DIR}/report.txt"
SITE_DIR="${ROOT_DIR}/site"
BASE_URL="https://runbook.kineticgain.com"

mkdir -p "$REPORT_DIR" "$SITE_DIR"
analyze_handoffs "$REPORT_FILE"

total_handoffs="$(summary_value "$REPORT_FILE" total_handoffs)"
red_handoffs="$(summary_value "$REPORT_FILE" red_handoffs)"
yellow_handoffs="$(summary_value "$REPORT_FILE" yellow_handoffs)"
green_handoffs="$(summary_value "$REPORT_FILE" green_handoffs)"
avg_blockers="$(summary_value "$REPORT_FILE" avg_blockers)"

handoff_rows="$(awk -F'|' '
  $1=="handoff" {
    printf "<tr><td><b>%s</b><br><span class=\"section-note\">%s → %s</span></td><td>%s</td><td>%s</td><td>%s</td><td><span class=\"status %s\">%s</span></td><td>%s</td></tr>\n",
      $3, $4, $5, $10, $8, $9=="true"?"yes":"no", $12=="red"?"bad":($12=="yellow"?"warn":"green"), toupper($12), $14
  }' "$REPORT_FILE")"

handoff_cards="$(awk -F'|' '
  $1=="handoff" {
    printf "<div class=\"card\"><div class=\"eyebrow\">%s · %s → %s</div><h3>%s</h3><p>SLA %sh elapsed %sh, blockers %s, evidence complete: %s.</p><p>%s</p></div>\n",
      $2, $4, $5, $3, $7, $8, $10, $9=="true"?"yes":"no", $15
  }' "$REPORT_FILE")"

ownership_rows="$(awk -F'|' '
  $1=="handoff" {
    printf "<tr><td><b>%s</b></td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>\n",
      $3, $4, $5, $13, $9=="true"?"complete":"incomplete"
  }' "$REPORT_FILE")"

evidence_rows="$(awk -F'|' '
  $1=="handoff" {
    printf "<tr><td><b>%s</b></td><td>%s</td><td>%s</td><td>%s</td></tr>\n",
      $3, $9=="true"?"Complete":"Incomplete", $11, $15
  }' "$REPORT_FILE")"

base_css=':root{--bg:#070a0f;--panel:#0b1220;--line:rgba(120,255,170,.18);--line2:rgba(120,255,170,.10);--text:#e9f3ff;--muted:rgba(233,243,255,.72);--muted2:rgba(233,243,255,.55);--bert:#37ff8b;--bert2:#19c7ff;--warn:#ffcc66;--bad:#ff5c7a;--plum:#b88cff;--shadow:0 18px 60px rgba(0,0,0,.55);--mono:ui-monospace,SFMono-Regular,Menlo,Monaco,Consolas,"Courier New",monospace;--sans:ui-sans-serif,system-ui,-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif}*{box-sizing:border-box}html,body{height:100%}body{margin:0;font-family:var(--sans);color:var(--text);background:radial-gradient(1200px 600px at 20% -10%, rgba(55,255,139,.18), transparent 60%),radial-gradient(900px 520px at 90% 0%, rgba(25,199,255,.16), transparent 55%),radial-gradient(1000px 600px at 50% 110%, rgba(55,255,139,.10), transparent 60%),linear-gradient(180deg,#05070c 0%,#070a0f 35%,#05070c 100%)}.grid-bg{position:fixed;inset:0;pointer-events:none;opacity:.12;z-index:-1;background-image:linear-gradient(to right, rgba(55,255,139,.14) 1px, transparent 1px),linear-gradient(to bottom, rgba(55,255,139,.10) 1px, transparent 1px);background-size:46px 46px;mask-image:radial-gradient(900px 600px at 40% 10%, #000 60%, transparent 100%)}.wrap{max-width:1280px;margin:0 auto;padding:24px 22px 80px}.topbar{display:flex;justify-content:space-between;align-items:flex-start;gap:14px;border-bottom:1px solid var(--line2);padding-bottom:14px;margin-bottom:22px;font-family:var(--mono);font-size:11px;letter-spacing:.16em;color:var(--muted);text-transform:uppercase}.topbar .left{color:var(--bert)}.topbar .right{text-align:right}.herorow{display:grid;grid-template-columns:1.45fr .85fr;gap:18px}@media (max-width:1000px){.herorow{grid-template-columns:1fr}}.hero,.mini,.tablewrap,.card{background:linear-gradient(180deg, rgba(11,18,32,.95), rgba(8,14,26,.92));border:1px solid var(--line);border-radius:22px;box-shadow:var(--shadow)}.hero{padding:28px 28px 24px;border-top:2px solid var(--bert2)}.hero h1{font-size:60px;line-height:.97;margin:0 0 18px;font-weight:800;letter-spacing:-.5px}@media (max-width:700px){.hero h1{font-size:40px}}.hero p,.mini p,.card p{color:var(--muted);font-size:15px;line-height:1.55}.chiprow{display:flex;flex-wrap:wrap;gap:8px}.meta-chip,.pill{font-family:var(--mono);font-size:11px;padding:7px 12px;border-radius:999px;border:1px solid var(--line);background:rgba(6,10,18,.4);color:var(--muted)}.side{display:flex;flex-direction:column;gap:14px}.mini{padding:18px}.mini .lbl,.section-note{font-family:var(--mono);font-size:10px;letter-spacing:.18em;text-transform:uppercase;color:var(--bert2)}.mini h3{margin:8px 0 6px;font-size:28px;line-height:1.02}.section{margin-top:34px}.sh{display:flex;justify-content:space-between;align-items:baseline;gap:14px;padding-bottom:10px;border-bottom:1px solid var(--line2);margin-bottom:14px}.sh h2{margin:0;font-size:24px;font-weight:600}.sh .note{font-family:var(--mono);font-size:11px;color:var(--muted2);letter-spacing:.16em;text-transform:uppercase}.kpis{display:grid;grid-template-columns:repeat(4,1fr);gap:12px}@media (max-width:900px){.kpis{grid-template-columns:repeat(2,1fr)}}@media (max-width:640px){.kpis{grid-template-columns:1fr}}.kpi,.card{border:1px solid var(--line);border-radius:16px;padding:16px;background:linear-gradient(180deg, rgba(11,18,32,.85), rgba(8,14,26,.65))}.kpi .v{font-family:var(--mono);font-size:28px;font-weight:700}.kpi .lbl{font-family:var(--mono);font-size:10px;letter-spacing:.18em;text-transform:uppercase;color:var(--muted);margin-top:6px}.kpi .h{font-size:12px;color:var(--muted);line-height:1.45;margin-top:8px}.green{color:var(--bert)}.cyan{color:var(--bert2)}.warn{color:var(--warn)}.plum{color:var(--plum)}.bad{color:var(--bad)}.cards{display:grid;grid-template-columns:repeat(3,1fr);gap:14px}@media (max-width:1000px){.cards{grid-template-columns:1fr}}.card h3{margin:8px 0 8px;font-size:22px}.card .eyebrow{font-family:var(--mono);font-size:10px;letter-spacing:.18em;text-transform:uppercase;color:var(--bert)}table{width:100%;border-collapse:collapse}th,td{padding:13px 14px;text-align:left;font-size:13.5px;vertical-align:top}thead th{font-family:var(--mono);font-size:11px;letter-spacing:.16em;text-transform:uppercase;color:var(--muted2);border-bottom:1px solid var(--line);background:rgba(11,18,32,.5)}tbody tr:hover{background:rgba(55,255,139,.03)}tbody td{color:var(--muted);border-bottom:1px solid var(--line2)}.tablewrap{padding:0;overflow:hidden}.status{display:inline-block;padding:4px 9px;border-radius:6px;border:1px solid currentColor;font-family:var(--mono);font-size:10px;letter-spacing:.1em;text-transform:uppercase}.quote{margin-top:34px;border:1px solid rgba(55,255,139,.22);background:radial-gradient(700px 200px at 0% 0%, rgba(55,255,139,.10), transparent 60%),linear-gradient(180deg, rgba(11,18,32,.92), rgba(8,14,26,.88));border-radius:18px;padding:24px 26px}.quote .lbl{font-family:var(--mono);font-size:11px;color:var(--bert);letter-spacing:.22em;text-transform:uppercase}.quote .q{margin-top:12px;font-size:32px;line-height:1.25;font-weight:600;max-width:1000px}footer{margin-top:30px;padding-top:14px;border-top:1px dashed var(--line2);display:flex;justify-content:space-between;gap:10px;flex-wrap:wrap;font-family:var(--mono);font-size:11px;color:var(--muted2);letter-spacing:.08em}a{color:var(--bert2);text-decoration:none}'

write_page() {
  local path="$1" title="$2" description="$3" canonical="$4" content="$5"
  mkdir -p "$(dirname "$path")"
  cat > "$path" <<EOF
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${title}</title>
  <meta name="description" content="${description}">
  <meta name="robots" content="index,follow">
  <meta property="og:title" content="${title}">
  <meta property="og:description" content="${description}">
  <meta property="og:type" content="website">
  <meta property="og:url" content="${canonical}">
  <link rel="canonical" href="${canonical}">
  <style>${base_css}</style>
</head>
<body>
  <div class="grid-bg"></div>
  <div class="wrap">
    ${content}
  </div>
</body>
</html>
EOF
}

overview_content="$(cat <<EOF
<div class="topbar"><div class="left">language atlas · shell / bash incident surface</div><div class="right"><div>runbook.kineticgain.com</div><div>platform / security / support handoff ops</div></div></div>
<div class="herorow">
  <section class="hero">
    <div class="chiprow"><span class="meta-chip">Bash analysis</span><span class="meta-chip">incident handoff</span><span class="meta-chip">owner routing</span><span class="meta-chip">evidence posture</span></div>
    <h1>Incident handoff runbook kit for owner gaps, SLA drift, and evidence-complete turnover.</h1>
    <p>A Bash-native operator surface for cross-team incident operations: score handoff pressure, evidence completeness, bridge posture, and next-owner routing from one portable runbook-oriented analysis path.</p>
    <div class="chiprow"><span class="pill">Route: /handoff-lane/</span><span class="pill">Route: /ownership-matrix/</span><span class="pill">Route: /evidence-posture/</span></div>
  </section>
  <aside class="side">
    <div class="mini"><div class="lbl">Handoffs in review</div><h3>${total_handoffs}</h3><p>Total modeled cross-team incident turnovers in the current queue.</p></div>
    <div class="mini"><div class="lbl">Escalated handoffs</div><h3>${red_handoffs}</h3><p>Transfers that should stay on-bridge until evidence and ownership are complete.</p></div>
    <div class="mini"><div class="lbl">Avg blockers</div><h3>${avg_blockers}</h3><p>Average unresolved blocker count across active incident handoffs.</p></div>
  </aside>
</div>
<section class="section"><div class="sh"><h2>Control-plane summary</h2><div class="note">Four KPIs from one Bash analysis path</div></div>
  <div class="kpis">
    <div class="kpi"><div class="v cyan">${total_handoffs}</div><div class="lbl">Handoffs</div><div class="h">Modeled incident transfers inside the shell-run report.</div></div>
    <div class="kpi"><div class="v bad">${red_handoffs}</div><div class="lbl">Escalate now</div><div class="h">Handoffs with SLA drift, owner gaps, or incomplete evidence.</div></div>
    <div class="kpi"><div class="v warn">${yellow_handoffs}</div><div class="lbl">Watch and transfer</div><div class="h">Handoffs that can move only if remaining blockers clear quickly.</div></div>
    <div class="kpi"><div class="v green">${green_handoffs}</div><div class="lbl">Stable handoffs</div><div class="h">Threads ready for clean owner transfer and archive.</div></div>
  </div>
</section>
<section class="section"><div class="sh"><h2>Handoff queue matrix</h2><div class="note">Bridge state, blockers, evidence completeness</div></div>
  <div class="tablewrap"><table><thead><tr><th>Incident</th><th>Bridge State</th><th>Blockers</th><th>Evidence Complete</th><th>Status</th><th>Top Risk</th></tr></thead><tbody>${handoff_rows}</tbody></table></div>
</section>
<section class="section"><div class="sh"><h2>Threads to route first</h2><div class="note">Buyer-readable turnover sequence</div></div><div class="cards">${handoff_cards}</div></section>
<div class="quote"><div class="lbl">Why this matters</div><div class="q">An incident handoff kit is monetizable when the same Bash analysis can become a turnover template pack, a war-room exit checklist, or embedded incident-governance support.</div></div>
<footer><div>discipline · incident turnover operations</div><div>focus · ownership / evidence / sla drift</div><div>overview snapshot</div><div><a href="https://github.com/mizcausevic-dev/">GitHub</a> · <a href="https://www.linkedin.com/in/mirzacausevic/">LinkedIn</a> · <a href="https://kineticgain.com/">Kinetic Gain</a></div></footer>
EOF
)"

handoff_lane_content="$(cat <<EOF
<div class="topbar"><div class="left">incident handoff runbook kit · handoff lane</div><div class="right"><div>cross-team incident turnover</div></div></div>
<section class="hero"><h1>Incident turnovers stay tied to explicit next owners.</h1><p>The handoff lane keeps bridge state, blockers, evidence readiness, and next action on one route so accountability does not drift between teams.</p></section>
<section class="section"><div class="cards">${handoff_cards}</div></section>
EOF
)"

ownership_content="$(cat <<EOF
<div class="topbar"><div class="left">incident handoff runbook kit · ownership matrix</div><div class="right"><div>owner routing</div></div></div>
<section class="hero"><h1>Owner routing stays portable and buyer-readable.</h1><p>This route shows the minimum handoff facts a team can gather in shell: source team, target team, top risk, and whether the evidence packet is actually complete.</p></section>
<section class="section"><div class="tablewrap"><table><thead><tr><th>Incident</th><th>Source</th><th>Target</th><th>Top Risk</th><th>Evidence</th></tr></thead><tbody>${ownership_rows}</tbody></table></div></section>
EOF
)"

evidence_content="$(cat <<EOF
<div class="topbar"><div class="left">incident handoff runbook kit · evidence posture</div><div class="right"><div>turnover packet review</div></div></div>
<section class="hero"><h1>Evidence completeness and next action stay auditable.</h1><p>The evidence route shows which handoffs are still missing packet quality, which ones can transfer, and which ones need the bridge to stay active until acknowledgment.</p></section>
<section class="section"><div class="tablewrap"><table><thead><tr><th>Incident</th><th>Evidence</th><th>Status</th><th>Recommended Action</th></tr></thead><tbody>${evidence_rows}</tbody></table></div></section>
EOF
)"

verification_content="$(cat <<EOF
<div class="topbar"><div class="left">incident handoff runbook kit · verification</div><div class="right"><div>bash only</div></div></div>
<section class="hero"><h1>One Bash analysis path, one static handoff proof surface.</h1><p>The same shell module produces the handoff analysis, site pages, smoke checks, and README proof assets. No app server is required to validate the operator surface.</p></section>
<section class="section"><div class="cards">
  <div class="card"><div class="eyebrow">Validation</div><h3>Shell runtime</h3><p>Validated with Git Bash demo, tests, site generation, smoke checks, and proof asset render.</p></div>
  <div class="card"><div class="eyebrow">Routes</div><h3>Static proof surface</h3><p>/ · /handoff-lane/ · /ownership-matrix/ · /evidence-posture/ · /verification/ · /docs/</p></div>
  <div class="card"><div class="eyebrow">Commercial path</div><h3>Templates and consulting</h3><p>Template pack planned, with embedded turnover and incident-governance support by engagement.</p></div>
</div></section>
EOF
)"

docs_content="$(cat <<EOF
<div class="topbar"><div class="left">incident handoff runbook kit · docs</div><div class="right"><div>kinetic gain embedded</div></div></div>
<section class="hero"><h1>Incident turnover proof for ownership, evidence, and SLA-aware handoff operations.</h1><p>This repo sits in the Language Atlas and Platform Engineering lane at once: real shell, incident-handoff framing, and a monetizable path into turnover packs, war-room checklists, and incident-governance engagements.</p></section>
<section class="section"><div class="cards">
  <div class="card"><div class="eyebrow">Tier 1</div><h3>Public proof</h3><p>Open-source incident handoff operator routes generated directly from Bash analysis.</p></div>
  <div class="card"><div class="eyebrow">Tier 2</div><h3>Template pack planned</h3><p>Turnover checklists, handoff packet formats, and incident runbook starters.</p></div>
  <div class="card"><div class="eyebrow">Tier 4</div><h3>Embedded by engagement</h3><p>Kinetic Gain can adapt the handoff kit for a platform, security, or support incident program.</p></div>
</div></section>
EOF
)"

write_page "${SITE_DIR}/index.html" "Incident handoff runbook kit" "Bash-native incident turnover operator surface for owner gaps, SLA drift, and evidence posture." "${BASE_URL}" "${overview_content}"
write_page "${SITE_DIR}/handoff-lane/index.html" "Handoff lane · Incident handoff runbook kit" "Incident turnover board and next-owner routing." "${BASE_URL}/handoff-lane/" "${handoff_lane_content}"
write_page "${SITE_DIR}/ownership-matrix/index.html" "Ownership matrix · Incident handoff runbook kit" "Portable Bash owner-routing matrix for incident handoffs." "${BASE_URL}/ownership-matrix/" "${ownership_content}"
write_page "${SITE_DIR}/evidence-posture/index.html" "Evidence posture · Incident handoff runbook kit" "Evidence completeness and transfer posture for incident runbooks." "${BASE_URL}/evidence-posture/" "${evidence_content}"
write_page "${SITE_DIR}/verification/index.html" "Verification · Incident handoff runbook kit" "Validation and commercial path for the shell incident surface." "${BASE_URL}/verification/" "${verification_content}"
write_page "${SITE_DIR}/docs/index.html" "Docs · Incident handoff runbook kit" "Incident handoff documentation and monetization path." "${BASE_URL}/docs/" "${docs_content}"

cat > "${SITE_DIR}/robots.txt" <<EOF
User-agent: *
Allow: /
Sitemap: ${BASE_URL}/sitemap.xml
EOF

cat > "${SITE_DIR}/sitemap.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url><loc>${BASE_URL}</loc><lastmod>2026-05-28</lastmod></url>
  <url><loc>${BASE_URL}/handoff-lane/</loc><lastmod>2026-05-28</lastmod></url>
  <url><loc>${BASE_URL}/ownership-matrix/</loc><lastmod>2026-05-28</lastmod></url>
  <url><loc>${BASE_URL}/evidence-posture/</loc><lastmod>2026-05-28</lastmod></url>
  <url><loc>${BASE_URL}/verification/</loc><lastmod>2026-05-28</lastmod></url>
  <url><loc>${BASE_URL}/docs/</loc><lastmod>2026-05-28</lastmod></url>
</urlset>
EOF

printf 'Generated site at %s\n' "${SITE_DIR}"
