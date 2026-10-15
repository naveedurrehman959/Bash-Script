#!/usr/bin/env bats

setup() {
  PROJECT_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  export HR_SYSLOG=0
  source "$PROJECT_ROOT/lib/common.sh"
  source "$PROJECT_ROOT/lib/rotate.sh"
  LOGDIR="$BATS_TEST_TMPDIR/logs"
  "$PROJECT_ROOT/scripts/make-sample-logs.sh" "$LOGDIR" >/dev/null
}

@test "old logs are compressed and recent logs are untouched" {
  run rotate_logs "$LOGDIR" 7 5 0
  [ "$status" -eq 0 ]
  [ -f "$LOGDIR/app.log" ]
  [ ! -e "$LOGDIR/nginx-access.log" ]
  compgen -G "$LOGDIR/nginx-access.log.*.gz"
}

@test "file names with spaces are rotated" {
  run rotate_logs "$LOGDIR" 7 5 0
  [ ! -e "$LOGDIR/payment service.log" ]
  compgen -G "$LOGDIR/payment service.log.*.gz"
}

@test "retention keeps only the newest KEEP archives" {
  run rotate_logs "$LOGDIR" 7 5 0
  [ "$(compgen -G "$LOGDIR/app.log.*.gz" | wc -l)" -eq 5 ]
  [ ! -e "$LOGDIR/app.log.20240101.gz" ]
  [ ! -e "$LOGDIR/app.log.20240102.gz" ]
  [ -e "$LOGDIR/app.log.20240107.gz" ]
}

@test "compressed archive keeps all data" {
  rotate_logs "$LOGDIR" 7 5 0 2>/dev/null
  [ "$(zcat "$LOGDIR"/nginx-access.log.*.gz | wc -l)" -eq 500 ]
}

@test "empty stale logs are purged, non-log files kept" {
  rotate_logs "$LOGDIR" 7 5 0 2>/dev/null
  [ ! -e "$LOGDIR/empty.log" ]
  [ -f "$LOGDIR/notes.txt" ]
}

@test "dry run changes nothing" {
  before=$(find "$LOGDIR" -printf '%P|%s|%T@\n' | sort)
  run rotate_logs "$LOGDIR" 7 5 1
  [ "$status" -eq 0 ]
  [[ "$output" == *"compressed=2 deleted=2 dry_run=1"* ]]
  after=$(find "$LOGDIR" -printf '%P|%s|%T@\n' | sort)
  [ "$before" = "$after" ]
}

@test "invalid arguments are rejected" {
  run rotate_logs "$LOGDIR" abc 5 0
  [ "$status" -eq 1 ]
  run rotate_logs "$BATS_TEST_TMPDIR/missing" 7 5 0
  [ "$status" -eq 1 ]
}
