#!/usr/bin/env bats

setup() {
  PROJECT_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  BIN="$PROJECT_ROOT/bin/healthrep"
  export HEALTHREP_LOCK="$BATS_TEST_TMPDIR/healthrep.lock"
  LOGDIR="$BATS_TEST_TMPDIR/logs"
  "$PROJECT_ROOT/scripts/make-sample-logs.sh" "$LOGDIR" >/dev/null
}

@test "-h prints usage and exits 0" {
  run "$BIN" -h
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "unknown option exits 2" {
  run "$BIN" -q -Z
  [ "$status" -eq 2 ]
}

@test "missing option argument exits 2" {
  run "$BIN" -q -d
  [ "$status" -eq 2 ]
}

@test "non-numeric days exits 2" {
  run "$BIN" -q -d abc
  [ "$status" -eq 2 ]
}

@test "config file is applied and the CLI overrides it" {
  cat >"$BATS_TEST_TMPDIR/t.conf" <<EOF
LOG_DIR=$LOGDIR
KEEP=3
EOF
  run "$BIN" -q -H -c "$BATS_TEST_TMPDIR/t.conf" -k 2
  [ "$status" -eq 0 ]
  [ "$(compgen -G "$LOGDIR/app.log.*.gz" | wc -l)" -eq 2 ]
}

@test "dry run with zero disk threshold exits 10 and keeps files" {
  run "$BIN" -q -n -l "$LOGDIR" -D 0
  [ "$status" -eq 10 ]
  [ -f "$LOGDIR/nginx-access.log" ]
}

@test "report is written to the report directory" {
  run "$BIN" -q -R -D 100 -M 100 -o "$BATS_TEST_TMPDIR/reports"
  [[ "$status" -eq 0 || "$status" -eq 10 ]]
  f=$(compgen -G "$BATS_TEST_TMPDIR/reports/health-*.json")
  jq -e '.disk.used_pct | type == "number"' "$f"
}

@test "second instance exits 4 while the lock is held" {
  exec 8>"$HEALTHREP_LOCK"
  flock -n 8
  run "$BIN" -q -R -H
  exec 8>&-
  [ "$status" -eq 4 ]
}
