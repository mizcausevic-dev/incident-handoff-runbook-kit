#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/src/incident_handoff_runbook.sh"

report_file="$(mktemp)"
trap 'rm -f "${report_file}"' EXIT

bash -n "${ROOT_DIR}/src/incident_handoff_runbook.sh"
bash -n "${ROOT_DIR}/scripts/generate_site.sh"
bash -n "${ROOT_DIR}/scripts/run_demo.sh"
bash -n "${ROOT_DIR}/scripts/smoke_check.sh"
bash -n "${ROOT_DIR}/scripts/render_readme_assets.sh"

analyze_handoffs "${report_file}"

[[ "$(summary_value "${report_file}" total_handoffs)" == "4" ]] || { echo "Expected 4 handoffs." >&2; exit 1; }
[[ "$(summary_value "${report_file}" red_handoffs)" -ge 1 ]] || { echo "Expected at least one red handoff." >&2; exit 1; }
grep -q "handoff|IH-204|" "${report_file}" || { echo "Missing IH-204 in report." >&2; exit 1; }
grep -q "escalate-now" "${report_file}" || { echo "Expected an escalate-now lane." >&2; exit 1; }

echo "All tests passed."
