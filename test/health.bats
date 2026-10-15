#!/usr/bin/env bats

setup() {
  PROJECT_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  export HR_SYSLOG=0
  source "$PROJECT_ROOT/lib/common.sh"
  source "$PROJECT_ROOT/lib/health.sh"
}

@test "disk_usage_pct returns an integer between 0 and 100" {
  run disk_usage_pct /
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^[0-9]+$ ]]
  [ "$output" -le 100 ]
}

@test "mem_used_pct returns an integer" {
  run mem_used_pct
  [[ "$output" =~ ^[0-9]+$ ]]
}

@test "http_check reports 000 for a closed port" {
  run http_check http://127.0.0.1:9/
  [ "$status" -eq 0 ]
  [ "$output" = "000" ]
}

@test "build_report emits valid JSON with the required keys" {
  run build_report / ""
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '(.host|length>0) and (.disk.used_pct|type=="number") and (.memory.used_pct|type=="number") and (.top_mem_procs|type=="array") and .http==null'
}

@test "evaluate_report passes a healthy report" {
  r='{"disk":{"mount":"/","used_pct":40},"memory":{"used_pct":30},"failed_units":0,"http":null}'
  run evaluate_report "$r" 90 90
  [ "$status" -eq 0 ]
  [[ "$output" == *"all health checks passed"* ]]
}

@test "evaluate_report flags every breach and returns 10" {
  r='{"disk":{"mount":"/","used_pct":95},"memory":{"used_pct":97},"failed_units":2,"http":{"url":"http://x/","status":503}}'
  run evaluate_report "$r" 90 90
  [ "$status" -eq 10 ]
  [[ "$output" == *"disk / at 95% (max 90%)"* ]]
  [[ "$output" == *"memory at 97% (max 90%)"* ]]
  [[ "$output" == *"2 failed systemd unit(s)"* ]]
  [[ "$output" == *"http http://x/ returned 503"* ]]
}
