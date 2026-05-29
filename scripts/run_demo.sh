#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/src/incident_handoff_runbook.sh"

report_file="$(mktemp)"
trap 'rm -f "${report_file}"' EXIT

analyze_handoffs "${report_file}"

echo "Scenario: Incident handoff runbook kit"
echo "Handoffs: $(summary_value "${report_file}" total_handoffs)"
echo "Escalated: $(summary_value "${report_file}" red_handoffs)"
echo "Watch and transfer: $(summary_value "${report_file}" yellow_handoffs)"
echo "Avg blockers: $(summary_value "${report_file}" avg_blockers)"
echo "Handoffs needing immediate routing:"
awk -F'|' '$1=="handoff" && $12=="red" { printf " - %s (%s -> %s): %s\n", $3, $4, $5, $15 }' "${report_file}"
