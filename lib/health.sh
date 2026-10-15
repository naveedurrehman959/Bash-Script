# shellcheck shell=bash
# health.sh - stub, implemented in Task 4.
build_report() {
  printf '{"stub":true,"mount":"%s"}\n' "$1"
}
evaluate_report() {
  log WARN "evaluate_report not implemented yet"
}
