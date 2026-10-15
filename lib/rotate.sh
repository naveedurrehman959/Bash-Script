# shellcheck shell=bash
# rotate.sh - log rotation for healthrep (sourced).

# rotate_logs DIR DAYS KEEP [DRYRUN]
rotate_logs() {
  local dir=$1 days=$2 keep=$3 dry=${4:-0}
  local f dest compressed=0 deleted=0 minutes
  local -a victims=()

  if [[ ! -d $dir ]]; then
    log ERROR "log directory not found: $dir"
    return 1
  fi
  if ! is_uint "$days" || ! is_uint "$keep"; then
    log ERROR "days and keep must be non-negative integers"
    return 1
  fi
  minutes=$((days * 1440))

  # 1. Compress old, non-empty *.log files (NUL-safe loop).
  while IFS= read -r -d '' f; do
    dest="$f.$(date -r "$f" +%Y%m%d).gz"
    if [[ -e $dest ]]; then
      dest="$f.$(date -r "$f" +%Y%m%d%H%M%S).gz"
    fi
    if [[ $dry -eq 1 ]]; then
      log INFO "DRY-RUN would compress: $f -> $dest"
    else
      gzip -c -- "$f" >"$dest"
      touch -r "$f" -- "$dest"
      rm -f -- "$f"
      log DEBUG "compressed: $f"
    fi
    compressed=$((compressed + 1))
  done < <(find "$dir" -maxdepth 1 -type f -name '*.log' ! -empty -mmin +"$minutes" -print0)

  # 2. Retention: keep the newest $keep archives per base log name.
  #    Input lines look like: "1716800000.1234567890 sandbox/logs/app.log.20240101.gz"
  mapfile -t victims < <(
    find "$dir" -maxdepth 1 -type f -name '*.log.*.gz' -printf '%T@ %p\n' |
      sort -rn |
      awk -v keep="$keep" '{
        path = substr($0, index($0, " ") + 1)
        # TODO 1: copy path into "base" and strip the ".<digits>.gz" suffix with sub()
        # TODO 2: count archives per base in an array; print path once the count exceeds keep
      }'
  )
  for f in "${victims[@]}"; do
    if [[ $dry -eq 1 ]]; then
      log INFO "DRY-RUN would delete: $f"
    else
      rm -f -- "$f"
      log DEBUG "deleted: $f"
    fi
    deleted=$((deleted + 1))
  done

  # 3. Purge empty stale logs (classic find | xargs, NUL-delimited).
  if [[ $dry -eq 0 ]]; then
    find "$dir" -maxdepth 1 -type f -name '*.log' -empty -mmin +"$minutes" -print0 |
      xargs -0 -r rm -f --
  fi

  log INFO "rotation done dir=$dir compressed=$compressed deleted=$deleted dry_run=$dry"
}
