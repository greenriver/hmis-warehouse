#!/usr/bin/env ruby
###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Only load dotenv in development (Docker containers have env vars already set)
begin
  require 'dotenv'
  Dotenv.load('.env', '.env.local')
rescue LoadError
  # dotenv not available (e.g., in Docker production/staging containers)
  # Environment variables are already set, so we can proceed
end

pgpass_entries = []

# Primary database
if ENV['DATABASE_HOST']
  pgpass_entries << [
    ENV['DATABASE_HOST'],
    ENV['DATABASE_PORT'] || '5432',
    '*',
    ENV['DATABASE_USER'] || 'postgres',
    ENV['DATABASE_PASS'] || 'postgres',
  ].join(':')
end

# Warehouse database
if ENV['WAREHOUSE_DATABASE_HOST']
  pgpass_entries << [
    ENV['WAREHOUSE_DATABASE_HOST'],
    ENV['WAREHOUSE_DATABASE_PORT'] || '5432',
    '*',
    ENV['WAREHOUSE_DATABASE_USER'] || 'postgres',
    ENV['WAREHOUSE_DATABASE_PASS'] || 'postgres',
  ].join(':')
end

# Health database
if ENV['HEALTH_DATABASE_HOST']
  pgpass_entries << [
    ENV['HEALTH_DATABASE_HOST'],
    ENV['HEALTH_DATABASE_PORT'] || '5432',
    '*',
    ENV['HEALTH_DATABASE_USER'] || 'postgres',
    ENV['HEALTH_DATABASE_PASS'] || 'postgres',
  ].join(':')
end

# Reporting database
if ENV['REPORTING_DATABASE_HOST']
  pgpass_entries << [
    ENV['REPORTING_DATABASE_HOST'],
    ENV['REPORTING_DATABASE_PORT'] || '5432',
    '*',
    ENV['REPORTING_DATABASE_USER'] || 'postgres',
    ENV['REPORTING_DATABASE_PASS'] || 'postgres',
  ].join(':')
end

# CAS database (optional)
if ENV['CAS_DATABASE_HOST']
  pgpass_entries << [
    ENV['CAS_DATABASE_HOST'],
    ENV['CAS_DATABASE_PORT'] || '5432',
    '*',
    ENV['CAS_DATABASE_USER'] || 'postgres',
    ENV['CAS_DATABASE_PASS'] || 'postgres',
  ].join(':')
end

# Remove duplicates
pgpass_entries.uniq!

# Write to stdout (can be redirected to ~/.pgpass or .pgpass)
puts pgpass_entries.join("\n")
