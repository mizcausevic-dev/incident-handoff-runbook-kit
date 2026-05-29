#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later

set -euo pipefail

sample_handoffs() {
  cat <<'EOF'
IH-204|checkout-degradation|platform-reliability|revenue-systems|critical|2.0|3.1|false|2|war-room-active|Payment retries are unstable and revenue-side owner packet is incomplete
IH-211|identity-incident|security-operations|support-operations|high|4.0|2.5|true|1|bridge-live|Support KB is ready but customer-impact wording needs final review
IH-223|schema-drift|webops|content-systems|high|6.0|5.4|false|1|triage|Editorial fallback path is set, but incident timeline is still fragmented
IH-230|crm-backfill|data-platform|revops|medium|8.0|4.2|true|0|monitoring|Data freshness recovered and handoff notes are clean
EOF
}

status_for_handoff() {
  local severity="$1" sla_hours="$2" elapsed_hours="$3" evidence_complete="$4" blockers="$5" bridge_state="$6"
  if [[ "$severity" == "critical" && "$elapsed_hours" > "$sla_hours" ]] || [[ "$evidence_complete" == "false" && "$blockers" -ge 2 ]] || [[ "$bridge_state" == "war-room-active" && "$blockers" -ge 2 ]]; then
    echo "red"
  elif [[ "$evidence_complete" == "false" || "$blockers" -ge 1 || "$bridge_state" == "triage" ]]; then
    echo "yellow"
  else
    echo "green"
  fi
}

lane_for_status() {
  local status="$1"
  case "$status" in
    red) echo "escalate-now" ;;
    yellow) echo "watch-and-transfer" ;;
    *) echo "stable-handoff" ;;
  esac
}

action_for_status() {
  local status="$1" target_team="$2"
  case "$status" in
    red) echo "Complete the handoff packet, assign ${target_team}, and keep the bridge active until acknowledgment." ;;
    yellow) echo "Transfer to ${target_team} with a named owner and close remaining evidence gaps in the next cycle." ;;
    *) echo "Maintain the handoff into ${target_team} and archive the packet as clean proof." ;;
  esac
}

analyze_handoffs() {
  local output="${1:-}"
  local lines=()
  local red=0 yellow=0 green=0 total_blockers=0

  while IFS='|' read -r id incident source_team target_team severity sla_hours elapsed_hours evidence_complete blockers bridge_state top_risk; do
    [[ -z "${id}" ]] && continue
    local status lane action
    status="$(status_for_handoff "$severity" "$sla_hours" "$elapsed_hours" "$evidence_complete" "$blockers" "$bridge_state")"
    lane="$(lane_for_status "$status")"
    action="$(action_for_status "$status" "$target_team")"

    case "$status" in
      red) ((red+=1)) ;;
      yellow) ((yellow+=1)) ;;
      green) ((green+=1)) ;;
    esac
    ((total_blockers+=blockers))

    lines+=("${id}|${incident}|${source_team}|${target_team}|${severity}|${sla_hours}|${elapsed_hours}|${evidence_complete}|${blockers}|${bridge_state}|${status}|${lane}|${top_risk}|${action}")
  done < <(sample_handoffs)

  local avg_blockers="0.0"
  if [[ ${#lines[@]} -gt 0 ]]; then
    avg_blockers="$(awk -v total="$total_blockers" -v count="${#lines[@]}" 'BEGIN { printf "%.1f", total / count }')"
  fi

  if [[ -n "$output" ]]; then
    mkdir -p "$(dirname "$output")"
    {
      printf 'summary|total_handoffs|%s\n' "${#lines[@]}"
      printf 'summary|red_handoffs|%s\n' "$red"
      printf 'summary|yellow_handoffs|%s\n' "$yellow"
      printf 'summary|green_handoffs|%s\n' "$green"
      printf 'summary|avg_blockers|%s\n' "$avg_blockers"
      for line in "${lines[@]}"; do
        printf 'handoff|%s\n' "$line"
      done
    } > "$output"
  else
    printf 'summary|total_handoffs|%s\n' "${#lines[@]}"
    printf 'summary|red_handoffs|%s\n' "$red"
    printf 'summary|yellow_handoffs|%s\n' "$yellow"
    printf 'summary|green_handoffs|%s\n' "$green"
    printf 'summary|avg_blockers|%s\n' "$avg_blockers"
    for line in "${lines[@]}"; do
      printf 'handoff|%s\n' "$line"
    done
  fi
}

summary_value() {
  local report="$1" key="$2"
  awk -F'|' -v key="$key" '$1=="summary" && $2==key { print $3 }' "$report"
}
