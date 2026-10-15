# Lab Practice Guide: Log Rotation and System Health Reporter

**Level:** Beginner to Intermediate  
**Role Scenario:** Junior DevOps Engineer  
**Platform:** Ubuntu Linux  
**Language:** Bash Shell Scripting  
**Time Spent:** 2 hours 37 minutes

---

## 1. Lab Overview

In this lab, you will build a robust Bash automation tool that manages application logs and monitors basic Linux system health.

Imagine that you are a junior DevOps engineer working for a company that hosts several applications on Ubuntu servers. Application logs are growing continuously, consuming disk space, and making troubleshooting difficult.

Your task is to develop a script that can:

- Rotate old application log files.
- Compress rotated logs using gzip.
- Remove logs older than a configured retention period.
- Monitor filesystem disk usage.
- Check whether specified services or processes are running.
- Generate a system-health report.
- Validate command-line arguments and configuration.
- Handle errors safely.
- Write automated tests and pass ShellCheck.

## 2. Learning Objectives

After completing this lab, you should understand how to:

1. Write reusable Bash functions.
2. Split a Bash project into multiple files.
3. Read configuration values from a file.
4. Parse command-line options.
5. Use `find`, `gzip`, `awk`, `df`, and `ps`.
6. Use `jq` to work with JSON reports.
7. Prevent simultaneous script executions with `flock`.
8. Handle errors and exit codes.
9. Test Bash scripts using positive and negative test cases.
10. document and publish a DevOps project on GitHub.

## 3. Project Directory Structure

Create the following directory structure:

```text
healthrep-lab/
├── bin/
│   └── healthrep
├── lib/
│   ├── common.sh
│   ├── rotate.sh
│   └── health.sh
├── config/
│   └── healthrep.conf
├── logs/
│   └── .gitkeep
├── reports/
│   └── .gitkeep
├── tests/
│   └── test_healthrep.sh
├── README.md
└── LAB_PRACTICE_GUIDE.md
```

### Purpose of each directory

| Path | Purpose |
|---|---|
| `bin/healthrep` | Main executable script |
| `lib/common.sh` | Shared functions, logging, and validation |
| `lib/rotate.sh` | Log rotation, compression, and retention |
| `lib/health.sh` | Disk and service health checks |
| `config/healthrep.conf` | Default configuration |
| `logs/` | Safe location for practice log files |
| `reports/` | Generated health reports |
| `tests/` | Automated test scripts |

## 4. Phase 1 — Prepare Ubuntu

Update package information:

```bash
sudo apt update
```

Install the required utilities:

```bash
sudo apt install -y \
  bash \
  coreutils \
  findutils \
  gzip \
  gawk \
  jq \
  curl \
  util-linux \
  shellcheck \
  git
```

Verify the installations:

```bash
bash --version
find --version
gzip --version
jq --version
shellcheck --version
flock --version
```

Check your current location:

```bash
pwd
```

## 5. Phase 2 — Create the Project

Create the directories:

```bash
mkdir -p ~/healthrep-lab/{bin,lib,config,logs,reports,tests}
cd ~/healthrep-lab
```

Create placeholder files:

```bash
touch logs/.gitkeep
touch reports/.gitkeep
touch bin/healthrep
touch lib/common.sh
touch lib/rotate.sh
touch lib/health.sh
touch config/healthrep.conf
touch tests/test_healthrep.sh
touch README.md
touch LAB_PRACTICE_GUIDE.md
```

Verify the structure:

```bash
find . -maxdepth 3 -type f | sort
```

**Checkpoint:** Confirm that all directories and files exist before adding code.

## 6. Phase 3 — Configure the Application

Open the configuration file:

```bash
nano config/healthrep.conf
```

Add the default settings supported by your implementation. For example:

```bash
LOG_DIR="./logs"
REPORT_DIR="./reports"
RETENTION_DAYS=7
MAX_LOG_SIZE_MB=10
DISK_THRESHOLD=80
SERVICE_NAMES=""
```

Save with `Ctrl+O`, press `Enter`, and exit with `Ctrl+X`.

These values are examples. Your script must define the actual supported configuration keys and validate their values.

Configuration requirements:

- Use `KEY=VALUE` format.
- Allow command-line options to override configuration values.
- Reject invalid numeric ranges.
- Avoid sourcing untrusted configuration files blindly.
- Document defaults and allowed values in `README.md`.

**Checkpoint:** Confirm that the application reads configuration correctly and that command-line overrides take precedence.

## 7. Phase 4 — Implement Shared Functions

Open the shared library:

```bash
nano lib/common.sh
```

Implement reusable functions for:

- Displaying informational messages.
- Displaying warnings and errors.
- Checking required commands.
- Validating numeric inputs.
- Creating required directories.
- Handling exit codes.
- Supporting debug or verbose output.

Keep common functions in this file instead of duplicating them in other scripts.

Suggested exit-code contract:

| Exit code | Meaning |
|---:|---|
| `0` | Success |
| `1` | General operational failure |
| `2` | Invalid command-line usage |
| `3` | Configuration error |
| `4` | Missing dependency |
| `10` | Another execution already holds the lock |

Use the same exit-code meanings consistently throughout the project.

## 8. Phase 5 — Implement Log Rotation

Open the rotation library:

```bash
nano lib/rotate.sh
```

Implement the log-rotation functionality.

### Required behavior

1. Locate eligible log files in the configured log directory.
2. Identify files that exceed the configured size threshold, if size-based rotation is enabled.
3. Rotate files without overwriting existing archives.
4. Compress rotated logs using gzip.
5. Apply the configured retention policy.
6. Report failures clearly.
7. Avoid following unexpected paths or deleting files outside the configured log directory.

### Create practice logs

Run:

```bash
cd ~/healthrep-lab

printf 'Application started\n' > logs/app.log
printf 'Warning: example event\n' >> logs/app.log
printf 'Error: simulated failure\n' >> logs/app.log
```

Inspect the file:

```bash
cat logs/app.log
ls -lh logs/
```

For size-based rotation, generate a larger test file:

```bash
yes 'Example application log entry' | head -n 20000 > logs/large-app.log
```

Check its size:

```bash
du -h logs/large-app.log
```

Run your script's log-rotation mode using the actual options implemented by your program.

After rotation, inspect the results:

```bash
find logs -maxdepth 1 -type f -printf '%f %s bytes\n' | sort
```

If compression is enabled, verify an archive with:

```bash
gzip -t logs/*.gz
```

Run the compression check only when at least one `.gz` archive exists.

**Checkpoint:** Confirm that eligible logs are rotated, archives are readable, and files that do not meet the rotation criteria remain untouched.

## 9. Phase 6 — Implement System Health Checks

Open the health-check library:

```bash
nano lib/health.sh
```

Implement checks for the following metrics.

### A. Disk usage

Use:

```bash
df -P
```

For a specific filesystem:

```bash
df -h /
```

Your script should compare measured disk utilization against the configured threshold.

For example, if the threshold is `80`, a filesystem reporting `85%` usage should produce a warning.

Do not assume that the root filesystem is the only filesystem worth monitoring. Support the filesystems defined by your lab requirements.

### B. Service or process status

Use:

```bash
ps -ef
```

For a quick manual check of a process:

```bash
pgrep -af ssh
```

Choose an appropriate method based on what your script promises to check. A process check does not necessarily prove that an application is healthy or responding to requests.

If your lab uses systemd services, you may also check:

```bash
systemctl is-active ssh
```

The service name can vary by Ubuntu installation.

### C. Report generation

The script should record useful information such as:

- Report timestamp.
- Filesystem usage.
- Warning or healthy status.
- Configured service or process checks.
- Log-rotation results.
- Errors encountered during execution.

If JSON output is required, generate valid JSON rather than manually concatenating unescaped strings.

Validate a generated report with:

```bash
jq . reports/health-report.json
```

Replace the path with the report filename configured in your implementation.

**Checkpoint:** Confirm that the script detects high disk usage, reports service-check results accurately, and generates valid output.

## 10. Phase 7 — Build the Main CLI

Open the main script:

```bash
nano bin/healthrep
```

The main script should:

1. Load its supporting libraries.
2. Parse command-line arguments.
3. Load the configuration.
4. Apply CLI overrides.
5. Validate all effective settings.
6. Check required dependencies.
7. Acquire an execution lock when appropriate.
8. Run the requested operations.
9. Return a meaningful exit code.

The lab's planned command-line interface includes these options:

| Option | Intended purpose |
|---|---|
| `-h` | Show help |
| `-v` | Verbose output |
| `-V` | Display version |
| `-c` | Specify a configuration file |
| `-l` | Specify the log directory |
| `-d` | Configure retention days |
| `-k` | Configure a size-related value |
| `-m` | Configure a disk-usage threshold |
| `-u` | Configure a service or process target |
| `-D` | Configure a numeric value |
| `-M` | Configure another supported numeric setting |
| `-o` | Specify output |
| `-R` | Run a rotation-related operation |
| `-H` | Run health checks |
| `-n` | Configure a count or limit |
| `-q` | Quiet mode |

**Important:** These descriptions must match the actual implementation. Do not assign multiple conflicting meanings to the same option. Update this table after finalizing the script's CLI.

Test help:

```bash
cd ~/healthrep-lab
bash bin/healthrep -h
echo "Exit code: $?"
```

Test version:

```bash
bash bin/healthrep -V
echo "Exit code: $?"
```

Test an invalid option:

```bash
bash bin/healthrep -Z
echo "Exit code: $?"
```

**Checkpoint:** Help and version should work without running destructive operations. Invalid options should return the documented usage error.

## 11. Phase 8 — Run Static Analysis

ShellCheck identifies common Bash scripting problems.

From the project root:

```bash
cd ~/healthrep-lab
shellcheck -x bin/healthrep lib/*.sh
```

If the command reports warnings:

1. Read the warning code and message.
2. Locate the relevant file and line.
3. Fix the underlying issue where possible.
4. Run ShellCheck again.

Do not suppress warnings merely to make the command appear successful. If a specific warning is a false positive, document and narrowly scope the suppression.

**Success criterion:** All project scripts pass the intended ShellCheck checks without unexplained warnings.

## 12. Phase 9 — Validate Command-Line Inputs

Test invalid arguments and confirm the expected exit codes.

| Test | Example | Expected result |
|---|---|---|
| Help | `bash bin/healthrep -h` | `0` |
| Unknown option | `bash bin/healthrep -Z` | `2` |
| Invalid quiet-mode argument | `bash bin/healthrep -q -d x` | `2` |
| Out-of-range numeric value | `bash bin/healthrep -q -D 101` | `2` |
| Invalid zero value | `bash bin/healthrep -q -k 0` | `2` |

These are acceptance-test examples for the planned interface. Ensure the final CLI implements these exact cases before using them as pass/fail criteria.

To inspect an exit code:

```bash
bash bin/healthrep -Z
status=$?
printf 'Exit code: %s\n' "$status"
```

Do not rely only on error messages. The exit code is part of the script's interface and should be tested independently.

## 13. Phase 10 — Create Automated Tests

Open the test script:

```bash
nano tests/test_healthrep.sh
```

Create tests for:

- Help output.
- Version output.
- Invalid arguments.
- Numeric boundary values.
- Missing configuration files.
- Missing dependencies, where testable.
- Successful report generation.
- Invalid JSON output.
- Log rotation and compression.
- Retention behavior.
- Lock contention.
- Failure handling.

### Example manual test loop

After implementing the CLI, you can run:

```bash
cd ~/healthrep-lab

for args in \
  "-h" \
  "-V" \
  "-Z" \
  "-q -d x" \
  "-q -D 101" \
  "-q -k 0"
do
    printf '\nTesting: %s\n' "$args"
    bash bin/healthrep $args
    printf 'Exit code: %s\n' "$?"
done
```

This simple loop is suitable for controlled lab arguments without embedded spaces or shell metacharacters. For a production-quality test harness, represent each argument as a separate array element and compare actual exit codes with expected values.

### Test design principle

Each test should verify both:

1. The command's exit code.
2. The expected observable result, such as output, archive creation, or report contents.

Do not run destructive tests against real system logs. Use temporary directories and disposable test data.

## 14. Phase 11 — Test Log Retention Safely

Create a disposable test directory:

```bash
mkdir -p ~/healthrep-lab/tmp-test/logs
```

Create an old test file:

```bash
touch ~/healthrep-lab/tmp-test/logs/old.log
```

Inspect its timestamp:

```bash
stat ~/healthrep-lab/tmp-test/logs/old.log
```

For a controlled age-based test, set the modification time using:

```bash
touch -d '10 days ago' ~/healthrep-lab/tmp-test/logs/old.log
```

Verify the timestamp again:

```bash
stat ~/healthrep-lab/tmp-test/logs/old.log
```

Run your retention logic only against the disposable test directory.

Then inspect the result:

```bash
find ~/healthrep-lab/tmp-test -type f -print
```

**Safety requirements:**

- Never test deletion against `/var/log` or another production directory.
- Do not use broad commands such as `sudo rm -rf` to clean up a lab.
- Ensure retention logic is constrained to the configured log directory.
- Confirm the target path before any deletion.
- Consider adding a dry-run mode before enabling actual deletion.

## 15. Phase 12 — Test Locking and Error Handling

If the script uses `flock`, test how it behaves when another instance holds the same lock.

Review the locking logic and confirm that:

- A second execution cannot perform conflicting work.
- Lock failures produce a clear message.
- The documented lock-related exit code is returned.
- Locks are released when the process exits.
- Temporary files are cleaned up safely.
- Error paths do not leave incomplete reports that look successful.

You should also test an unwritable report directory, a missing input directory, and a missing dependency where possible.

Perform these tests in a disposable directory and avoid changing permissions on important system directories.

## 16. Phase 13 — End-to-End Practice

Once individual components pass their tests, perform a full run.

### Step 1: Review the configuration

```bash
cd ~/healthrep-lab
cat config/healthrep.conf
```

### Step 2: Inspect test logs

```bash
find logs -maxdepth 1 -type f -ls
```

### Step 3: Run the health check

Use the health-check option documented by your actual implementation.

### Step 4: Run log rotation

Use the rotation option documented by your actual implementation.

### Step 5: Validate generated reports

If your implementation produces JSON:

```bash
find reports -maxdepth 1 -type f -print
```

Then validate the actual JSON report:

```bash
jq . reports/health-report.json
```

### Step 6: Re-run automated checks

```bash
shellcheck -x bin/healthrep lib/*.sh
bash tests/test_healthrep.sh
```

The test command assumes your test file is a runnable Bash test harness.

**Checkpoint:** You should be able to explain what each operation does, which configuration values affect it, and how errors are reported.

## 17. Phase 14 — Troubleshooting

### Problem: `Permission denied`

Check file permissions:

```bash
ls -l bin/healthrep
```

Make the main script executable:

```bash
chmod +x bin/healthrep
```

Then run:

```bash
./bin/healthrep -h
```

### Problem: `jq: command not found`

Install jq:

```bash
sudo apt update
sudo apt install -y jq
```

### Problem: ShellCheck warnings

Run:

```bash
shellcheck -x bin/healthrep lib/*.sh
```

Fix the warnings in the relevant files and rerun the command.

### Problem: JSON report is invalid

Validate the report:

```bash
jq . reports/health-report.json
```

Check whether special characters, missing fields, or malformed quoting caused the error.

### Problem: No logs are rotated

Inspect the log directory:

```bash
find logs -maxdepth 1 -type f -ls
```

Check the configured log directory, size threshold, retention period, and the script's output. Make sure the test files satisfy the rotation rules.

### Problem: Script returns an unexpected exit code

Capture the result:

```bash
bash bin/healthrep -Z
status=$?
echo "$status"
```

Compare it with the documented exit-code contract.

## 18. Phase 15 — Git and GitHub Submission

Initialize Git if this is a new repository:

```bash
cd ~/healthrep-lab
git init
git status
```

Create a `.gitignore` file:

```bash
nano .gitignore
```
## run these command to succeed in lab

```bash
cd ~/healthrep-lab
shellcheck -x bin/healthrep lib/*.sh
bash tests/test_healthrep.sh
git status
```

```gitignore
# Runtime reports and generated logs
reports/*
!reports/.gitkeep
logs/*
!logs/.gitkeep

# Temporary test data
tmp-test/

# Local editor files
*.swp
*~
```

Review the ignore rules before committing. If you want to include sanitized example reports or sample logs, store them separately and document that they contain test data.

Stage the project:

```bash
git add .
git status
```

Commit:

```bash
git commit -m "Build Bash log rotation and system health reporter lab"
```

Connect the GitHub repository:

```bash
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/healthrep-lab.git
git push -u origin main
```

Replace `YOUR_USERNAME` with your GitHub username. If the repository already has a remote, inspect it with `git remote -v` instead of adding a duplicate.

## 19. Final Acceptance Checklist

Before considering the lab complete, verify each item:

- [ ] Project directory structure is correct.
- [ ] Main script and supporting libraries are implemented.
- [ ] Configuration is documented and validated.
- [ ] CLI arguments are validated.
- [ ] CLI values override configuration as documented.
- [ ] Log rotation works against disposable test data.
- [ ] Compression archives pass `gzip -t`.
- [ ] Retention removes only eligible files within the test directory.
- [ ] Disk usage checks return meaningful results.
- [ ] Service or process checks are documented accurately.
- [ ] JSON reports pass `jq` validation.
- [ ] Locking prevents conflicting concurrent executions.
- [ ] Error handling and exit codes are consistent.
- [ ] ShellCheck passes without unexplained warnings.
- [ ] Automated tests pass.
- [ ] README includes setup, usage, configuration, tests, and limitations.
- [ ] Git repository contains no secrets or unnecessary generated files.

## 20. Interview Questions

Practice answering these questions in your own words.

1. What problem does log rotation solve?
2. Why do we compress old logs?
3. What is the difference between `find` and `grep`?
4. How does `gzip` work?
5. What is the purpose of `set -euo pipefail`, and why must it be used carefully?
6. Why should scripts validate command-line arguments?
7. What is the difference between standard output and standard error?
8. What is an exit code in Linux?
9. How can `flock` prevent concurrent executions?
10. Why should a script generate valid JSON instead of manually building JSON strings?
11. What is the purpose of ShellCheck?
12. How would you safely test a script that deletes old files?
13. What is the difference between checking a process and checking application health?
14. How would you schedule the script using cron or a systemd timer?
15. How would you monitor this automation on multiple servers?

## 21. Possible Future Improvements

After the core lab passes, consider adding:

- A dry-run mode.
- Structured JSON logging.
- Unit tests using a Bash testing framework.
- A systemd service and timer.
- Email or webhook alerts.
- A Prometheus-compatible metrics endpoint or textfile output.
- CI with GitHub Actions and ShellCheck.
- Containerized testing.
- Configuration validation in CI.
- Documentation for operational recovery.

Do not claim these enhancements are implemented until you have built and tested them.

## 22. Project Summary

This lab demonstrates foundational DevOps skills through a practical Linux automation problem. You will practice Bash scripting, filesystem operations, log retention, system monitoring, configuration management, testing, static analysis, and Git-based collaboration.

The strongest portfolio submission is not merely a script that runs once. It is a script that validates its inputs, handles failures safely, produces verifiable output, and includes repeatable tests.

**Final goal:** Build a reliable, testable, and well-documented Bash utility that a junior DevOps engineer could explain, troubleshoot, and improve.
