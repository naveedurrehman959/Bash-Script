# HealthRep — Bash Automation, Log Rotation & System Health Monitoring

**A production-inspired DevOps automation lab using Bash, Linux utilities, JSON, automated testing, and systemd.**

![Bash](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnubash&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Ubuntu-E95420?logo=ubuntu&logoColor=white)
![Testing](https://img.shields.io/badge/Testing-Bats--Core-blue)
![Quality](https://img.shields.io/badge/Code%20Quality-ShellCheck-brightgreen)
![Automation](https://img.shields.io/badge/Automation-systemd%20%7C%20cron-orange)
![License](https://img.shields.io/badge/License-MIT-blue)

## Project Overview

HealthRep is a Bash automation tool designed to help Linux administrators and DevOps engineers monitor system health, rotate application logs, and automate routine maintenance.

In many environments, old application logs consume disk space, system services fail without timely detection, and fragile shell commands run through cron without proper error handling. HealthRep addresses these problems through a single, configurable, tested command-line tool.

The project demonstrates how to transform basic Bash scripts into a maintainable automation solution with safe file handling, structured JSON reports, automated tests, logging, and scheduled execution.

**Lab duration:** 2 hours 37 minutes

**Target environment:** Ubuntu Server 22.04 or a compatible Ubuntu system with systemd.

## Key Features

- **Automated log rotation:** Compress old, non-empty `.log` files into gzip archives.
- **Archive retention:** Keep only the newest configured number of archives per log.
- **Safe filename handling:** Support filenames containing spaces using NUL-delimited file processing.
- **Stale log cleanup:** Remove empty log files older than the configured retention age.
- **JSON health reports:** Collect disk usage, memory usage, system load, failed systemd units, and top memory-consuming processes.
- **HTTP endpoint monitoring:** Check an optional URL and report its HTTP status.
- **Threshold monitoring:** Detect disk, memory, failed-service, and HTTP health issues.
- **Documented exit codes:** Allow scripts and schedulers to distinguish normal runs, errors, and threshold breaches.
- **Safe configuration:** Parse an allow-listed `KEY=VALUE` configuration file without executing it as shell code.
- **Operational safeguards:** Use strict mode, traps, temporary directories, file locking, and signal handling.
- **Automated quality checks:** Integrate ShellCheck, shfmt, Bats, and a Git pre-commit hook.
- **Automated scheduling:** Deploy with a systemd service and timer, with cron as an alternative.

## Architecture

```text
                    HealthRep CLI
                    bin/healthrep
                          |
             +------------+------------+
             |                         |
        common.sh                  Configuration
      Logging/helpers             /etc/healthrep
             |
       +-----+------+
       |            |
    rotate.sh     health.sh
       |            |
   Find old logs   df, /proc, ps
   gzip archives   systemctl, curl
   Enforce limits  jq JSON report
       |            |
       +-----+------+
             |
       Exit status
       Syslog/journal
             |
       +-----+------+
       |            |
    systemd timer   cron
```

## Repository Structure

```text
healthrep-lab/
├── bin/
│   └── healthrep
├── lib/
│   ├── common.sh
│   ├── rotate.sh
│   └── health.sh
├── scripts/
│   ├── make-sample-logs.sh
│   └── check.sh
├── test/
│   ├── cli.bats
│   ├── health.bats
│   └── rotate.bats
├── githooks/
│   └── pre-commit
├── deploy/
│   ├── healthrep.conf
│   ├── healthrep.service
│   └── healthrep.timer
├── sandbox/
│   └── # Local demonstration files
├── PITFALLS.md
├── .gitignore
└── README.md
```

The `sandbox/` directory contains temporary lab data and is excluded from Git using `.gitignore`.

## Learning Objectives

By completing this project, you will learn how to:

1. Write safer Bash scripts using `set -Eeuo pipefail`.
2. Build a command-line interface using `getopts`.
3. Validate configuration values and command-line arguments.
4. Process filenames safely with `find -print0`, `xargs -0`, and `read -d ''`.
5. Compress log files and enforce archive retention.
6. Collect Linux system metrics and generate valid JSON with `jq`.
7. Handle failures, signals, and concurrent executions using traps and `flock`.
8. Record operational events through syslog and journald.
9. Write automated tests with Bats.
10. Enforce code quality through ShellCheck, shfmt, and Git hooks.
11. Deploy and schedule automation using systemd timers and cron.

## Prerequisites

- Basic Linux commands and directory navigation.
- Basic Bash scripting, variables, functions, loops, and conditions.
- Familiarity with file permissions, pipes, and redirection.
- Basic Git commands.
- An Ubuntu Server with sudo access and internet connectivity.

## Technology Stack

| Technology | Purpose |
|---|---|
| Bash | Automation and CLI implementation |
| find, xargs | Safe file discovery and cleanup |
| gzip | Log compression |
| awk, sed | Text processing and metrics |
| jq | JSON generation and threshold evaluation |
| df, /proc, ps | System health metrics |
| systemctl | Failed-service detection and scheduling |
| curl | HTTP endpoint monitoring |
| flock | Prevent concurrent executions |
| logger | Syslog integration |
| ShellCheck | Static analysis |
| shfmt | Bash formatting |
| Bats-core | Automated testing |
| Git hooks | Pre-commit quality gate |
| systemd and cron | Scheduled execution |

## Installation and Setup

### 1. Update Ubuntu

```bash
sudo apt-get update
sudo apt-get install -y \
  shellcheck shfmt jq curl git cron gzip \
  python3 bsdutils util-linux

sudo systemctl enable --now cron
```

### 2. Install Bats-core v1.11.0

```bash
rm -rf /tmp/bats-core

git clone --depth 1 --branch v1.11.0 \
  https://github.com/bats-core/bats-core.git \
  /tmp/bats-core

/tmp/bats-core/install.sh "$HOME/.local"

export PATH="$HOME/.local/bin:$PATH"
```

To make the PATH update persistent:

```bash
grep -qF '$HOME/.local/bin' ~/.bashrc ||
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
```

### 3. Verify the tools

```bash
bash --version | head -n 1
shellcheck --version
shfmt --version
bats --version
jq --version
flock --version
```

### 4. Create the project

If you have not created the repository yet:

```bash
mkdir -p ~/healthrep-lab/{bin,lib,scripts,test,deploy,githooks,sandbox}

cd ~/healthrep-lab

git init -b main

printf 'sandbox/\nreports/\n' > .gitignore
```

Follow the lab instructions to implement each file in the repository structure above.

## Usage

Run the tool from the project directory:

```bash
cd ~/healthrep-lab
```

### Display help and version

```bash
bin/healthrep -h
bin/healthrep -V
```

### Generate sample logs

```bash
scripts/make-sample-logs.sh sandbox/logs
```

### Perform a dry run

Preview log rotation without modifying files:

```bash
bin/healthrep -q -n -l sandbox/logs
```

### Rotate logs without generating a health report

```bash
bin/healthrep -q -H -l sandbox/logs -d 7 -k 5
```

### Generate a health report without rotating logs

```bash
bin/healthrep -q -R
```

### Check a web endpoint

```bash
bin/healthrep -q -R -u http://127.0.0.1:8080/
```

For a local test endpoint, start a temporary Python HTTP server:

```bash
mkdir -p sandbox/www
echo "ok" > sandbox/www/index.html

cd sandbox/www
python3 -m http.server 8080 --bind 127.0.0.1
```

Run the HealthRep command from another terminal.

### Save JSON reports

```bash
bin/healthrep -q -R -o reports
```

Inspect the latest report with:

```bash
jq . reports/health-*.json
```

**Note:** Report filenames have one-second timestamp resolution. Avoid multiple concurrent report-writing runs to the same directory within the same second.

## Command-Line Options

| Option | Description |
|---|---|
| `-c FILE` | Load a configuration file |
| `-l DIR` | Set the log directory |
| `-d DAYS` | Rotate logs older than the specified number of days |
| `-k N` | Retain N archives per log |
| `-m MOUNT` | Select the filesystem to monitor |
| `-u URL` | Check an HTTP endpoint |
| `-D PCT` | Set the maximum disk usage percentage |
| `-M PCT` | Set the maximum memory usage percentage |
| `-o DIR` | Save JSON reports to a directory |
| `-R` | Skip log rotation |
| `-H` | Skip health reporting |
| `-n` | Perform a dry run |
| `-q` | Disable syslog messages |
| `-v` | Enable debug logging |
| `-V` | Display the version |
| `-h` | Display help |

### Exit Codes

| Code | Meaning |
|---:|---|
| `0` | Successful execution; no threshold breach |
| `1` | Operational error |
| `2` | Invalid usage or configuration |
| `3` | Required dependency missing |
| `4` | Another instance is running |
| `10` | One or more health thresholds breached |
| `130` | Interrupted by SIGINT |
| `143` | Terminated by SIGTERM |

Exit code `10` is a monitoring result, not necessarily an execution failure. The systemd service uses `SuccessExitStatus=10` so threshold breaches can be reported without automatically marking the service as failed.

## JSON Health Report

The report includes:

- Hostname and UTC timestamp.
- Disk usage percentage and monitored mount.
- Memory usage percentage.
- One-minute load average and CPU count.
- Number of failed systemd units.
- Optional HTTP endpoint status.
- Top five memory-consuming processes.

Example structure:

```json
{
  "host": "ubuntu-server",
  "timestamp": "2026-10-15T07:00:00Z",
  "disk": {
    "mount": "/",
    "used_pct": 42
  },
  "memory": {
    "used_pct": 36
  },
  "load": {
    "one_min": 0.25,
    "cpus": 2
  },
  "failed_units": 0,
  "http": {
    "url": "http://127.0.0.1:8080/",
    "status": 200
  },
  "top_mem_procs": []
}
```

This is an illustrative example; actual values depend on the machine and its running processes. When no URL is configured, `http` is `null`.

### Threshold evaluation

The tool checks disk usage against `DISK_MAX`, memory usage against `MEM_MAX`, failed systemd units, and any configured HTTP endpoint.

A breach is logged and causes exit code `10`.

## Log Rotation and Retention

The rotation component performs three operations:

1. **Compression:** Compress non-empty `.log` files older than the configured age.
2. **Retention:** Keep only the newest configured number of matching gzip archives for each base log name.
3. **Cleanup:** Delete empty, stale `.log` files.

The implementation uses NUL-delimited file paths so filenames containing spaces are handled correctly.

Example:

```text
Before:
app.log
nginx-access.log
payment service.log
empty.log
notes.txt

After:
app.log
nginx-access.log.20261005.gz
payment service.log.20261006.gz
notes.txt
```

The dates above are illustrative. A current log remains untouched, old logs are compressed, empty stale logs are removed, and unrelated files remain unchanged.

The archive retention implementation assumes archive filenames follow the documented naming convention and do not contain newline characters.

## Testing and Code Quality

### Run ShellCheck

```bash
shellcheck -x bin/healthrep lib/*.sh scripts/*.sh
```

### Check formatting

```bash
shfmt -i 2 -ci -d \
  bin/healthrep lib/*.sh scripts/*.sh
```

### Run automated tests

```bash
bats test/
```

Run a specific test file:

```bash
bats test/rotate.bats
bats test/health.bats
bats test/cli.bats
```

### Run the complete quality gate

```bash
scripts/check.sh
```

The check script runs ShellCheck, verifies formatting, and executes the Bats test suite.

### Enable the Git pre-commit hook

```bash
git config core.hooksPath githooks
```

Every commit will run the project's quality checks. A commit is rejected when the checks fail.

**Expected result:** All automated tests pass, formatting is clean, and ShellCheck reports no findings in the checked project scripts.

## Deployment with systemd

HealthRep can be installed under `/opt/healthrep`, configured under `/etc/healthrep`, and scheduled with a systemd timer.

### Install the application

```bash
sudo install -d -m 0755 \
  /opt/healthrep/bin \
  /opt/healthrep/lib \
  /etc/healthrep \
  /var/lib/healthrep/reports

sudo install -m 0755 \
  bin/healthrep /opt/healthrep/bin/healthrep

sudo install -m 0644 \
  lib/*.sh /opt/healthrep/lib/

sudo ln -sfn \
  /opt/healthrep/bin/healthrep \
  /usr/local/bin/healthrep

sudo install -m 0644 \
  deploy/healthrep.conf \
  /etc/healthrep/healthrep.conf
```

### Install the service and timer

```bash
sudo install -m 0644 \
  deploy/healthrep.service \
  deploy/healthrep.timer \
  /etc/systemd/system/

sudo systemd-analyze verify \
  /etc/systemd/system/healthrep.service \
  /etc/systemd/system/healthrep.timer

sudo systemctl daemon-reload
sudo systemctl start healthrep.service
sudo systemctl enable --now healthrep.timer
```

### Verify the timer

```bash
systemctl is-enabled healthrep.timer
systemctl is-active healthrep.timer
systemctl list-timers healthrep.timer --no-pager
```

### Inspect service logs

```bash
sudo journalctl -u healthrep.service -n 30 --no-pager
sudo journalctl -t healthrep -n 20 --no-pager
```

The supplied timer schedules recurring execution every five minutes. The service runs as a one-shot task and uses the configured lock to prevent overlapping executions.

## Cron Alternative

Cron can also schedule HealthRep. Create the report directory first, then add a user crontab entry:

```bash
mkdir -p "$HOME/healthrep-lab/reports"

crontab -e
```

Example entry:

```cron
*/2 * * * * /usr/local/bin/healthrep -R -D 100 -M 100 -o /home/USER/healthrep-lab/reports >> /home/USER/healthrep-lab/reports/cron.log 2>&1
```

Replace `USER` with your actual Linux username.

Inspect the scheduled job:

```bash
crontab -l
tail -n 20 "$HOME/healthrep-lab/reports/cron.log"
```

Use either scheduler according to your operational requirements. Avoid unnecessary duplicate schedules for the same maintenance workload.

## Important Bash Pitfalls Learned

### 1. Arithmetic under strict mode

Avoid relying on post-increment when its result may be zero:

```bash
i=$((i + 1))
```

### 2. Preserve command-substitution failures

Instead of:

```bash
local result=$(some_command)
```

Use:

```bash
local result
result=$(some_command)
```

### 3. Avoid premature pipeline termination

With `pipefail`, `producer | head -n 1` can return status `141` when the producer receives SIGPIPE. Where appropriate, use an `awk` program that consumes the full input.

### 4. Understand `set -e`

Bash's errexit behavior depends on context. Failures inside conditions and certain `&&` or `||` lists may not terminate execution as expected.

### 5. Always quote file paths

Prefer:

```bash
rm -f -- "$file"
```

Avoid unquoted expansions and parsing filenames from `ls`.

More examples are documented in `PITFALLS.md`.

## Troubleshooting

| Problem | Recommended fix |
|---|---|
| `bats: command not found` | Export `PATH="$HOME/.local/bin:$PATH"` |
| ShellCheck cannot follow a library | Run from the repository root using `shellcheck -x` |
| `shfmt -d` reports differences | Run `shfmt -i 2 -ci -w` on the project scripts |
| Rotation skips a log | Check its age, directory, extension, and configured threshold |
| Filename with spaces breaks processing | Use NUL-delimited file handling and quote expansions |
| HealthRep exits with code `10` | Inspect the JSON report and threshold-breach messages |
| HealthRep exits with code `4` | Check whether another process holds the configured lock |
| No HTTP response | Check the URL, connectivity, listening service, and curl timeout |
| systemd service is marked failed after a breach | Verify `SuccessExitStatus=10` is configured |
| Cron produces no reports | Check absolute paths, directory permissions, and cron logs |
| Git commit is rejected | Run `scripts/check.sh`, correct the findings, and retry |

## Validation Checklist

Use the following commands to verify the main development components:

```bash
cd ~/healthrep-lab

# Project files
test -x bin/healthrep
test -f lib/common.sh
test -f lib/rotate.sh
test -f lib/health.sh

# Static analysis and formatting
shellcheck -x bin/healthrep lib/*.sh scripts/*.sh
shfmt -i 2 -ci -d bin/healthrep lib/*.sh scripts/*.sh

# Automated tests
bats test/

# JSON output
bin/healthrep -q -R 2>/dev/null | jq .

# CLI validation
bin/healthrep -q -Z
echo "Exit code: $?"

# Git quality gate
scripts/check.sh
```

The unknown-option example should return exit code `2`. The JSON command should produce a valid health report if the required tools and system metric sources are available.

Deployment checks require the service, timer, configuration, and installation steps to have been completed. Do not assume the timer is active merely because the repository files exist.

## Challenge Extensions

After completing the core lab, extend HealthRep with:

- **Size-based rotation:** Rotate large logs even when they are younger than the age threshold.
- **Report retention:** Keep only the newest configured number of JSON reports.
- **Additional tests:** Verify large-file rotation, retention boundaries, and report pruning.
- **CI pipeline:** Run ShellCheck, shfmt, and Bats automatically with GitHub Actions.
- **Container support:** Package the tool for a controlled container-based execution environment.
- **Monitoring integration:** Export metrics or forward health information to a monitoring platform.

Ensure every extension has automated tests and passes the quality gate before committing.

## Cleanup

If you deployed the application, disable its timer and remove its service before deleting the installation:

```bash
sudo systemctl disable --now healthrep.timer

sudo rm -f \
  /etc/systemd/system/healthrep.service \
  /etc/systemd/system/healthrep.timer

sudo systemctl daemon-reload
sudo systemctl reset-failed healthrep.service 2>/dev/null || true
```

Remove the cron entry separately if you configured one. Remove `/opt/healthrep`, `/etc/healthrep`, and `/var/lib/healthrep` only when you no longer need the installed application, configuration, or reports.

The complete cleanup procedure is documented in the lab instructions. Review commands carefully before removing files.

## Key Takeaways

This project demonstrates that Bash automation is more than combining shell commands. Reliable automation requires careful input validation, safe file handling, predictable exit codes, structured reports, failure handling, and repeatable testing.

HealthRep combines Linux administration with DevOps practices: automation, code quality, testing, version control, logging, and scheduled operations.

**Skills demonstrated:** Bash scripting, Linux administration, log management, system monitoring, JSON processing, ShellCheck, shfmt, Bats, Git hooks, systemd, cron, and operational troubleshooting.

---

**Author:** Naveed ur Rehman

**Project:** HealthRep — Bash Automation and System Health Monitoring

**Repository:** `healthrep-lab`

**Time spent:** 2 hours 37 minutes

*Built as a hands-on DevOps learning project to practice reliable Linux automation and production-inspired operational workflows.*

