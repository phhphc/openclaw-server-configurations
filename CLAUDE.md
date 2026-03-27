# CLAUDE.md

Guidelines for working on this repository.

## Project

A single Bash script (`setup.sh`) to provision a fresh Ubuntu server. It is run once as root.

## Key conventions

**Users** are declared in the `USERS` array at the top of `setup.sh`. All per-user steps loop over this array — add or remove a user name there only.

**Each concern is its own function.** Keep `install_packages`, `setup_users`, `setup_nvim`, and `setup_bashrc` focused. If adding a new setup step, add a new function and call it from `main`.

**All steps must be idempotent.** The script must be safe to re-run without side effects. Use guard conditions (`if ! id`, `if [[ -d ... ]]`, `append_once`, `snap list <pkg> && snap refresh <pkg> || snap install <pkg> --classic`) wherever an operation would fail or duplicate on a second run.

**Error handling.** The script runs with `set -euo pipefail`. Any command that is expected to fail (e.g. snap already installed) must be handled explicitly — do not suppress errors with bare `|| true` unless the failure is truly inconsequential.

**Package grouping.** In `apt install` calls, group packages by purpose on separate lines (CLI tools, office, Python libs, etc.) for readability.

## Commit style

Short imperative subject line, no period. Add a body when the reason is not obvious from the subject. Example:

```
Make snap installs idempotent

snap install exits non-zero if the package is already present.
Fall back to snap refresh so re-runs do not abort the script.
```

## Validation

Always run `bash -n setup.sh` to check syntax before committing.
