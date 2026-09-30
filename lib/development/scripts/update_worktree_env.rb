###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Rewrites a freshly-created git worktree's local environment so it uses isolated
# databases and its own compose project, without touching the main development/test
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

# NAME_PREFIX (copied in from the primary .envrc) marks a second full install on
# the same machine; its worktrees must use its containers and volumes, not main's.
envrc = File.join(worktree_path, '.envrc')
# Same reading as worktree_pre_remove.sh: the last export wins, as it does for direnv.
name_prefix = File.file?(envrc) ? File.read(envrc).scan(/^export NAME_PREFIX=["']?([^"'\s]*)/).flatten.last.to_s : ''
# Compose project names must be lowercase.
abort "NAME_PREFIX must be lowercase letters, digits, and hyphens (got #{name_prefix.inspect})" unless name_prefix.match?(/\A[a-z0-9-]*\z/)
project = "#{name_prefix}hmis-warehouse"
# The shared cache volumes below are named after the primary's compose project, so
# it has to be exactly NAME_PREFIX + hmis-warehouse (or this worktree's own name on a re-run).
primary_project = File.file?(envrc) ? File.read(envrc).scan(/^export COMPOSE_PROJECT_NAME=["']?([^"'\s]*)/).flatten.last.to_s : ''
abort "COMPOSE_PROJECT_NAME must be #{project} when NAME_PREFIX is #{name_prefix.inspect} (got #{primary_project.inspect})" unless primary_project.empty? || [project, "#{project}-#{name_dash}"].include?(primary_project)

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

# --- .env.local / .env.development.local (development databases) ----------
# Checkouts diverge on which of these two gitignored files actually defines
# the DEV_DB_KEYS/DATABASE_CAS_DB values (dotenv-rails reads both), so rewrite
# whichever one(s) each worktree actually has them in.
['.env.local', '.env.development.local'].each do |filename|
  rewrite(File.join(worktree_path, filename)) do |content|
    DEV_DB_KEYS.each { |key| content = append_db_suffix(content, key, db_suffix) }
    # CAS is the external boston-cas database; disable it in worktrees so the
    # database.yml `cas:` section (guarded by .present?) is dropped entirely.
    content = set_value(content, 'DATABASE_CAS_DB', '')
    content
  end
end

# --- .env.test.local (test databases) --------------------------------------
# Created from the committed .env.test; the spec service loads it last (added to
# its env_file in the copied docker-compose.override.yml). A copy from the primary
# may set only some keys; the rest are filled in from .env.test so every test
# database gets the suffix rather than falling through to the primary's.
env_test = File.join(worktree_path, '.env.test')
env_test_local = File.join(worktree_path, '.env.test.local')
if File.file?(env_test)
  File.write(env_test_local, File.read(env_test)) unless File.file?(env_test_local)
  rewrite(env_test_local) do |content|
    missing = TEST_DB_KEYS.reject { |key| content.match?(/^#{Regexp.escape(key)}=/) }
    File.read(env_test).each_line do |line|
      next unless missing.any? { |key| line.start_with?("#{key}=") }

      content += "\n" unless content.empty? || content.end_with?("\n")
      content += line
    end
    TEST_DB_KEYS.each { |key| content = append_db_suffix(content, key, db_suffix) }
    content = set_value(content, 'CAS_DATABASE_DB_TEST', '')
    content
  end
else
  warn '  WARNING: .env.test not found; skipping .env.test.local'
end

# --- .envrc (direnv: compose project, traefik) ------------------------------
# Traefik stays off: worktree web labels would otherwise register routers that
# compete with the primary's.
rewrite(envrc) do |content|
  content = upsert_export(content, 'COMPOSE_PROJECT_NAME', "#{project}-#{name_dash}")
  content = upsert_export(content, 'TRAEFIK_ENABLED', 'false')
  content
end

# --- docker-compose.override.yml -------------------------------------------
# Per-worktree copy (gitignored). Line-based edits preserve the file's comments
# (a Psych round-trip would strip them). All edits are idempotent.
override = File.join(worktree_path, 'docker-compose.override.yml')

# Index range of SERVICE's body lines (after its `  service:` line), or nil when
# the override doesn't mention the service. Comments at any indent stay inside the body.
def service_body(lines, service)
  sidx = lines.index { |l| l.match?(/^ {2}#{Regexp.escape(service)}:\s*$/) }
  return unless sidx

  block_end = (sidx + 1...lines.size).find { |i| lines[i].match?(/^ {0,2}[^\s#]/) } || lines.size
  (sidx + 1...block_end)
end

# Adds `  service:` right after the top-level `services:` line; returns its body start.
def add_service(lines, service)
  idx = lines.index { |l| l.match?(/^services:\s*$/) }
  return unless idx

  lines.insert(idx + 1, "  #{service}:\n")
  idx + 2
end

# Sets SERVICE's container_name, replacing one the primary's override already sets.
def set_container_name(lines, service, name)
  name_line = "    container_name: #{name}\n"
  body = service_body(lines, service)
  cidx = body&.find { |i| lines[i].match?(/^ {4}container_name:/) }
  return lines[cidx] = name_line if cidx

  at = body ? body.first : add_service(lines, service)
  lines.insert(at, name_line) if at
end

rewrite(override) do |content|
  lines = content.lines

  # 1. yarn: a unique container_name so asset watchers can run concurrently.
  #    spec: load .env.test.local (compose appends it to the base env_file) unless
  #    the primary's override already does.
  set_container_name(lines, 'yarn', "#{project}-yarn-#{name_dash}")
  unless content.include?('.env.test.local')
    body = service_body(lines, 'spec')
    at = body ? body.first : add_service(lines, 'spec')
    lines.insert(at, "    env_file:\n      - .env.test.local\n") if at
  end

  # 2. web: a unique container_name (override replaces the base's fixed name).
  set_container_name(lines, 'web', "#{project}-web-#{name_dash}")

  # 3. Point the shared cache volumes at the primary's existing (project-prefixed)
  #    volumes so worktrees reuse them instead of creating empty per-project
  #    copies. The project prefix keeps them from colliding with other apps'
  #    identically-named volumes.
  ['bundle_trixie', 'node_modules_trixie', 'rails_cache_trixie'].each do |vol|
    vidx = lines.index { |l| l.match?(/^ {2}#{Regexp.escape(vol)}:\s*$/) }
    next unless vidx
    next if lines[vidx + 1].to_s.match?(/^\s+external:\s*true/)

    lines[vidx] = "  #{vol}:\n    external: true\n    name: #{project}_#{vol}\n"
  end

  lines.join
end

puts "Worktree environment configured for '#{branch}' (db suffix _wt_#{db_suffix}, compose project #{project}-#{name_dash})."
