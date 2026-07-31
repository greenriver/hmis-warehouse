#!/usr/bin/env bash
#
# worktrunk pre-start hook: prepare a freshly-created git worktree for isolated
# development. Copies the gitignored env/compose files a new worktree lacks from
# the primary worktree, then rewrites them (isolated DB names, per-worktree
# domain, compose project, traefik router) via update_worktree_env.rb.
#
# Wired up in .config/wt.toml:
#   pre-start = "bash lib/development/scripts/worktree_pre_start.sh {{ worktree_path }} {{ branch }} {{ primary_worktree_path }}"
#
# Idempotent: files already present in the worktree are left in place and the
# Ruby rewrite never double-applies its changes.

set -euo pipefail

worktree_path="${1:?worktree path required}"
branch="${2:?branch required}"
primary_path="${3:?primary worktree path required}"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Preparing worktree $worktree_path (branch $branch)"

# Files that are gitignored (so absent in a fresh worktree) but required to boot
# and to isolate the worktree. .env.test and docker-compose.yml are tracked.
for f in .env.local .env.development.local .envrc docker-compose.override.yml; do
  if [ ! -f "$primary_path/$f" ]; then
    echo "  WARNING: $primary_path/$f not found; skipping"
  elif [ -f "$worktree_path/$f" ]; then
    echo "  $f already present; leaving as-is"
  else
    cp "$primary_path/$f" "$worktree_path/$f"
    echo "  copied $f"
  fi
done

ruby "$script_dir/update_worktree_env.rb" "$worktree_path" "$branch"
