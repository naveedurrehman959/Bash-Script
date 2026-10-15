#!/usr/bin/env bash
# make-sample-logs.sh DIR - create a reproducible set of demo log files.
set -euo pipefail

dir=${1:?usage: make-sample-logs.sh DIR}
mkdir -p -- "$dir"
find "$dir" -mindepth 1 -maxdepth 1 -delete

gen_lines() {
  awk -v n="$1" -v app="$2" 'BEGIN {
    for (i = 1; i <= n; i++) {
      status = (i % 17 == 0) ? 500 : 200
      printf "2024-05-01T10:%02d:%02d %s request id=%d status=%d\n", int(i / 60) % 60, i % 60, app, i, status
    }
  }'
}

gen_lines 2000 app >"$dir/app.log"
gen_lines 500 nginx >"$dir/nginx-access.log"
touch -d '10 days ago' "$dir/nginx-access.log"
gen_lines 300 payment >"$dir/payment service.log"
touch -d '9 days ago' "$dir/payment service.log"
: >"$dir/empty.log"
touch -d '30 days ago' "$dir/empty.log"
echo "not a log" >"$dir/notes.txt"
touch -d '40 days ago' "$dir/notes.txt"

for i in 1 2 3 4 5 6 7; do
  gen_lines 100 app | gzip >"$dir/app.log.2024010${i}.gz"
  touch -d "$((27 - i)) days ago" "$dir/app.log.2024010${i}.gz"
done

echo "Sample logs created in $dir:"
ls -l --time-style=+%F "$dir"
