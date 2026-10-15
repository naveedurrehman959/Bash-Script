# shellcheck shell=bash
# common.sh - shared helpers for healthrep (sourced, never executed).

: "${HR_VERBOSE:=0}"
: "${HR_SYSLOG:=1}"
: "${HR_TAG:=healthrep}"

# log LEVEL MESSAGE... -> stderr, plus syslog via logger unless HR_SYSLOG=0
log() {
  local level=$1 prio
  shift
  case $level in
    DEBUG)
      [[ $HR_VERBOSE -eq 1 ]] || return 0
      prio=debug
      ;;
    INFO) prio=info ;;
    WARN) prio=warning ;;
    ERROR) prio=err ;;
    *) prio=notice ;;
  esac
  printf '%s [%s] %s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$level" "$*" >&2
  if [[ $HR_SYSLOG -eq 1 ]] && command -v logger >/dev/null 2>&1; then
    logger -t "$HR_TAG" -p "user.$prio" -- "$level: $*" || true
  fi
}

# die MESSAGE [EXIT_CODE]
die() {
  local code=${2:-1}
  log ERROR "$1"
  exit "$code"
}

# require_cmd CMD... -> exit 3 if any command is missing
require_cmd() {
  local c
  for c in "$@"; do
    command -v "$c" >/dev/null 2>&1 || die "required command not found: $c" 3
  done
}

# is_uint VALUE -> true if VALUE is a non-negative integer
is_uint() {
  [[ $1 =~ ^[0-9]+$ ]]
}
bad_fn() { echo $1; }
