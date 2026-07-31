###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Rewrites a freshly-created git worktree's local environment so it uses isolated
# databases and its own web domain, without touching the main development/test
# databases. Invoked by lib/development/scripts/worktree_pre_start.sh (the
# worktrunk pre-start hook).
#
# Usage: ruby lib/development/scripts/update_worktree_env.rb <worktree_path> <branch>
#
# All edits are idempotent so the script can be re-run on an existing worktree.

worktree_path = ARGV[0]
branch = ARGV[1]

abort 'usage: update_worktree_env.rb <worktree_path> <branch>' if worktree_path.to_s.empty? || branch.to_s.empty?
abort "worktree path does not exist: #{worktree_path}" unless File.directory?(worktree_path)

# Two sanitized forms of the branch name:
#   name_dash  — for domains, compose project, traefik router, container names ([a-z0-9-])
#   db_suffix  — for postgres database names, appended after `_wt_` ([a-z0-9_], unquoted-safe)
name_dash = branch.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/\A-+|-+\z/, '')
db_suffix = branch.downcase.gsub(/[^a-z0-9]+/, '_').gsub(/\A_+|_+\z/, '')

DEV_DB_KEYS = [
  'DATABASE_APP_DB',
  'WAREHOUSE_DATABASE_DB',
  'HEALTH_DATABASE_DB',
  'REPORTING_DATABASE_DB',
].freeze

TEST_DB_KEYS = [
  'DATABASE_APP_DB_TEST',
  'WAREHOUSE_DATABASE_DB_TEST',
  'HEALTH_DATABASE_DB_TEST',
  'REPORTING_DATABASE_DB_TEST',
].freeze

# Append `_wt_<db_suffix>` to the value of KEY on its `KEY=value` line, unless the
# value is empty or already suffixed. Only rewrites lines that already exist.
def append_db_suffix(content, key, suffix)
  content.gsub(/^(#{Regexp.escape(key)}=)([^\n]*)$/) do
    prefix = Regexp.last_match(1)
    value = Regexp.last_match(2).strip
    next "#{prefix}#{value}" if value.empty? || value.end_with?("_wt_#{suffix}")

    "#{prefix}#{value}_wt_#{suffix}"
  end
end

# Set KEY to an explicit value on its existing `KEY=...` line (no-op if absent).
def set_value(content, key, value)
  content.gsub(/^(#{Regexp.escape(key)}=)[^\n]*$/, "\\1#{value}")
end

# Upsert `export KEY=value` in a shell/direnv file (replace if present, else append).
def upsert_export(content, key, value)
  line = "export #{key}=#{value}"
  if content.match?(/^export #{Regexp.escape(key)}=[^\n]*$/)
    content.gsub(/^export #{Regexp.escape(key)}=[^\n]*$/, line)
  else
    content += "\n" unless content.empty? || content.end_with?("\n")
    "#{content}#{line}\n"
  end
end

def rewrite(path)
  return unless File.file?(path)

  original = File.read(path)
  updated = yield(original.dup)
  if updated == original
    puts "  #{File.basename(path)} already current"
  else
    File.write(path, updated)
    puts "  updated #{File.basename(path)}"
  end
end

# --- .env.local (development databases) -------------------------------------
env_local = File.join(worktree_path, '.env.local')
rewrite(env_local) do |content|
  DEV_DB_KEYS.each { |key| content = append_db_suffix(content, key, db_suffix) }
  # CAS is the external boston-cas database; disable it in worktrees so the
  # database.yml `cas:` section (guarded by .present?) is dropped entirely.
  content = set_value(content, 'DATABASE_CAS_DB', '')
  content
end

# --- .env.test.local (test databases) --------------------------------------
# Created from the committed .env.test; the spec service loads it last (added to
# its env_file in the copied docker-compose.override.yml).
env_test = File.join(worktree_path, '.env.test')
env_test_local = File.join(worktree_path, '.env.test.local')
if File.file?(env_test)
  File.write(env_test_local, File.read(env_test)) unless File.file?(env_test_local)
  rewrite(env_test_local) do |content|
    TEST_DB_KEYS.each { |key| content = append_db_suffix(content, key, db_suffix) }
    content = set_value(content, 'CAS_DATABASE_DB_TEST', '')
    content
  end
else
  warn '  WARNING: .env.test not found; skipping .env.test.local'
end

# --- .envrc (direnv: domain, compose project, traefik router) ---------------
envrc = File.join(worktree_path, '.envrc')
rewrite(envrc) do |content|
  content = upsert_export(content, 'FQDN', "hmis-warehouse-#{name_dash}.dev.test")
  content = upsert_export(content, 'COMPOSE_PROJECT_NAME', "hmis-warehouse-#{name_dash}")
  content = upsert_export(content, 'TRAEFIK_ROUTER_NAME', "op-#{name_dash}")
  content
end

# --- docker-compose.override.yml -------------------------------------------
# Per-worktree copy (gitignored). Line-based edits preserve the file's comments
# (a Psych round-trip would strip them). All edits are idempotent.
override = File.join(worktree_path, 'docker-compose.override.yml')
rewrite(override) do |content|
  lines = content.lines

  # 1. Add `spec` and `yarn` service blocks right after the top-level `services:`
  #    line (neither exists in the base override, so no duplicate-key risk).
  #    spec: adds .env.test.local (compose appends it to the base env_file).
  #    yarn: gives the asset watcher a unique container_name for concurrency.
  unless content.include?('.env.test.local')
    idx = lines.index { |l| l.match?(/^services:\s*$/) }
    if idx
      block = <<~BLOCK
        \  spec:
        \    env_file:
        \      - .env.test.local
        \  yarn:
        \    container_name: hmis-warehouse-yarn-#{name_dash}
      BLOCK
      lines.insert(idx + 1, block)
    end
  end

  # 2. Give the web service a unique container_name (override replaces the base's
  #    fixed name). Insert into the existing `web:` block if not already present.
  unless content.match?(/container_name:\s*hmis-warehouse-web-/)
    widx = lines.index { |l| l.match?(/^ {2}web:\s*$/) }
    lines.insert(widx + 1, "    container_name: hmis-warehouse-web-#{name_dash}\n") if widx
  end

  # 3. Point the shared cache volumes at main's existing (project-prefixed)
  #    volumes so worktrees reuse them instead of creating empty per-project
  #    copies. The `hmis-warehouse_` prefix keeps them from colliding with other
  #    apps' identically-named volumes.
  {
    'bundle_bookworm' => 'hmis-warehouse_bundle_bookworm',
    'node_modules_bookworm' => 'hmis-warehouse_node_modules_bookworm',
    'rails_cache_bookworm' => 'hmis-warehouse_rails_cache_bookworm',
  }.each do |vol, external_name|
    vidx = lines.index { |l| l.match?(/^ {2}#{Regexp.escape(vol)}:\s*$/) }
    next unless vidx
    next if lines[vidx + 1].to_s.match?(/^\s+external:\s*true/)

    lines[vidx] = "  #{vol}:\n    external: true\n    name: #{external_name}\n"
  end

  lines.join
end

puts "Worktree environment configured for '#{branch}' (db suffix _wt_#{db_suffix}, domain hmis-warehouse-#{name_dash}.dev.test)."
