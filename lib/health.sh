# shellcheck shell=bash
# health.sh - health metrics and JSON report for healthrep (sourced).

disk_usage_pct() {
  df -P -- "${1:-/}" | awk 'NR == 2 { gsub(/%/, "", $5); print $5 }'
}

mem_used_pct() {
  awk '/^MemTotal:/ {t = $2} /^MemAvailable:/ {a = $2}
       END { if (t > 0) printf "%d\n", (t - a) * 100 / t }' /proc/meminfo
}

load_1m() {
  cut -d' ' -f1 /proc/loadavg
}

failed_units() {
  systemctl list-units --state=failed --no-legend --plain 2>/dev/null |
    awk '{print $1}' | grep -c . || true
}

# http_check URL -> prints the HTTP status code (000 if unreachable)
http_check() {
  curl -s -o /dev/null -m 5 -w '%{http_code}' -- "$1" || true
}

# top_procs N -> JSON array of the N biggest memory consumers
top_procs() {
  ps -eo pid=,comm=,%mem= --sort=-%mem |
    awk -v n="${1:-5}" 'NR <= n { printf "%s\t%s\t%s\n", $1, $2, $3 }' |
    jq -R -n '[inputs | split("\t") | {pid: (.[0] | tonumber), comm: .[1], mem_pct: (.[2] | tonumber)}]'
}

# build_report MOUNT URL -> JSON document on stdout
build_report() {
  local mount=$1 url=$2 disk mem load cpus failed http="0" procs
  disk=$(disk_usage_pct "$mount")
  mem=$(mem_used_pct)
  load=$(load_1m)
  cpus=$(nproc)
  failed=$(failed_units)
  procs=$(top_procs 5)
  if [[ -n $url ]]; then
    http=$(http_check "$url")
  fi
  jq -n \
    --arg host "$(uname -n)" \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg mount "$mount" \
    --argjson disk "$disk" \
    --argjson mem "$mem" \
    --argjson load "$load" \
    --argjson cpus "$cpus" \
    --argjson failed "$failed" \
    --arg url "$url" \
    --arg http "$http" \
    --argjson procs "$procs" \
    '{
      host: $host,
      timestamp: $ts,
      disk: {mount: $mount, used_pct: $disk},
      memory: {used_pct: $mem},
      load: {one_min: $load, cpus: $cpus},
      failed_units: $failed,
      http: (if $url == "" then null else {url: $url, status: ($http | tonumber)} end),
      top_mem_procs: $procs
    }'
}

# evaluate_report REPORT_JSON DISK_MAX MEM_MAX -> returns 10 on any breach
evaluate_report() {
  local report=$1 disk_max=$2 mem_max=$3 breaches line
  breaches=$(jq -r --argjson d "$disk_max" --argjson m "$mem_max" '
    [
      (if .disk.used_pct > $d then "disk \(.disk.mount) at \(.disk.used_pct)% (max \($d)%)" else empty end)
      # TODO 1: memory breach  -> "memory at N% (max M%)"
      # TODO 2: failed units   -> "N failed systemd unit(s)"   (when .failed_units > 0)
      # TODO 3: http breach    -> "http URL returned CODE"      (when .http != null and .http.status != 200)
    ] | .[]' <<<"$report")
  if [[ -n $breaches ]]; then
    while IFS= read -r line; do
      log WARN "threshold breach: $line"
    done <<<"$breaches"
    return 10
  fi
  log INFO "all health checks passed"
}
