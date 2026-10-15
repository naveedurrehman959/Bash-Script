# Strict-mode pitfalls verified in this project
- ((i++)) returns 1 when the old value is 0 -> use i=$((i + 1))
- local x=$(cmd) hides cmd's exit status -> declare, then assign
- cmd | head under pipefail can return 141 (SIGPIPE) -> use awk 'NR<=n'
- set -e is ignored inside functions called from ||, &&, if, while
- traps run between commands: always put timeouts on network calls
