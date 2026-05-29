#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/src/incident_handoff_runbook.sh"

report_file="$(mktemp)"
trap 'rm -f "${report_file}"' EXIT
mkdir -p "${ROOT_DIR}/screenshots"

analyze_handoffs "${report_file}"

total_handoffs="$(summary_value "${report_file}" total_handoffs)"
red_handoffs="$(summary_value "${report_file}" red_handoffs)"
avg_blockers="$(summary_value "${report_file}" avg_blockers)"
top_handoff="$(awk -F'|' '$1=="handoff" && $12=="red" { print $3; exit }' "${report_file}")"
top_risk="$(awk -F'|' '$1=="handoff" && $12=="red" { print $14; exit }' "${report_file}")"

write_svg() {
  local path="$1" eyebrow="$2" title="$3" line1="$4" line2="$5" accent="$6"
  cat > "${path}" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="1600" height="900" viewBox="0 0 1600 900">
  <rect width="1600" height="900" fill="#05070c"/>
  <rect x="48" y="48" width="1504" height="804" rx="30" fill="#0b1220" stroke="#17324d" stroke-width="2"/>
  <text x="96" y="118" fill="${accent}" font-family="ui-monospace,Consolas,monospace" font-size="26" letter-spacing="6">${eyebrow}</text>
  <text x="96" y="196" fill="#f2f7ff" font-family="Georgia,Times New Roman,serif" font-size="58" font-weight="700">${title}</text>
  <text x="96" y="272" fill="#b8c9df" font-family="Segoe UI,Arial,sans-serif" font-size="30">${line1}</text>
  <text x="96" y="320" fill="#b8c9df" font-family="Segoe UI,Arial,sans-serif" font-size="30">${line2}</text>
</svg>
EOF
}

write_svg "${ROOT_DIR}/screenshots/01-overview.svg" "INCIDENT HANDOFF RUNBOOK KIT" "Bash proof for turnover pressure and ownership gaps." "Handoffs in review: ${total_handoffs} · escalated: ${red_handoffs} · avg blockers: ${avg_blockers}." "Static shell-generated operator routes stay buyer-readable." "#19c7ff"
write_svg "${ROOT_DIR}/screenshots/02-handoff-lane.svg" "HANDOFF LANE" "The riskiest incident transfers stay visible first." "Top escalated handoff: ${top_handoff}." "${top_risk}" "#37ff8b"
write_svg "${ROOT_DIR}/screenshots/03-evidence-posture.svg" "EVIDENCE POSTURE" "Evidence completeness and next-owner action stay explicit." "Incomplete packets keep the bridge active until acknowledgment is real." "Stable handoffs can transfer and archive with proof." "#ffcc66"
write_svg "${ROOT_DIR}/screenshots/04-verification.svg" "VERIFICATION" "The same Bash path drives analysis, pages, and proof assets." "Routes: /handoff-lane/ · /ownership-matrix/ · /evidence-posture/." "Template pack planned · consulting hook." "#b88cff"

echo "Rendered README assets."
