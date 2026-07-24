#!/usr/bin/env bash
#
# worktrunk pre-remove hook: tear down a worktree's isolated resources before the
# worktree directory is deleted. Removes the worktree's app containers and drops
# its `_wt_`-suffixed databases from the shared postgres container. Shared backing
# services and the external cache volumes are left untouched.
#
# Wired up in .config/wt.toml:
#   pre-remove = "bash lib/development/scripts/worktree_pre_remove.sh {{ worktree_path }} {{ branch }}"
#
# Runs in the worktree being removed (its env files still exist), so exact DB
# names are read back from .env.local / .env.test.local rather than recomputed.

# Note: no `set -e` — we want to continue past individual drop failures.
set -uo pipefail

worktree_path="${1:?worktree path required}"
branch="${2:?branch required}"

name_dash="$(printf '%s' "$branch" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')"
project="hmis-warehouse-${name_dash}"
db_container="hmis-warehouse-db"

# 1. Remove this worktree's app containers (web/yarn/dj). Shared services and the
#    external cache volumes are not affected (no `-v`).
if [ -d "$worktree_path" ]; then
  echo "Removing containers for compose project $project"
  ( cd "$worktree_path" && docker compose -p "$project" down --remove-orphans ) 2>/dev/null || \
    echo "  (nothing to remove or compose unavailable)"
fi

# 2. Drop the worktree's databases from the shared db container.
if ! docker ps --format '{{.Names}}' | grep -qx "$db_container"; then
  echo "WARNING: $db_container is not running; cannot drop databases automatically."
  echo "Once it is up, drop them manually, e.g.:"
  echo "  docker exec -i $db_container psql -U postgres -c 'DROP DATABASE IF EXISTS <name> WITH (FORCE);'"
  exit 0
fi

drop_db() {
  local dbname="$1"
  [ -z "$dbname" ] && return 0
  case "$dbname" in
    *_wt_*) ;;                                                # only worktree DBs
    *) echo "  skip (not a _wt_ database): $dbname"; return 0 ;;
  esac
  echo "  dropping $dbname"
  docker exec -i "$db_container" psql -U postgres -tc \
    "DROP DATABASE IF EXISTS \"$dbname\" WITH (FORCE);" >/dev/null || \
    echo "  WARNING: failed to drop $dbname"
}

db_names_from() {
  local file="$1"
  [ -f "$file" ] || return 0
  grep -E '^(DATABASE_APP_DB|WAREHOUSE_DATABASE_DB|HEALTH_DATABASE_DB|REPORTING_DATABASE_DB|DATABASE_APP_DB_TEST|WAREHOUSE_DATABASE_DB_TEST|HEALTH_DATABASE_DB_TEST|REPORTING_DATABASE_DB_TEST)=' "$file" \
    | sed -E 's/^[^=]+=//' | tr -d "\"'"
}

for f in "$worktree_path/.env.local" "$worktree_path/.env.test.local"; do
  while IFS= read -r dbname; do
    drop_db "$dbname"
  done < <(db_names_from "$f")
done

echo "Worktree resources for '$branch' cleaned up."
