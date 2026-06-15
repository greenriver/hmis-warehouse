# frozen_string_literal: true

###
# Rake tasks for the one-time Devise -> Keycloak user migration.
#
# TEMPORARY ops tooling. Human-run, console-only, per Deployment, in the
# migrate -> flip window. Nothing here runs on boot or in a request. Delete
# alongside Idp::Keycloak::UserImporter once all account data has been migrated.
#
# Drives Idp::Keycloak::UserImporter, reaching Keycloak through
# Idp::KeycloakService#partial_import (the partialImport Admin API).
#
# Migration scope (Idp::Keycloak::UserImporter.migration_scope): confirmed +
# active users. The confirmed_at filter also excludes invited-but-not-accepted
# users — they have no credential to carry and are provisioned on first JWT
# login after the flip.
#
# NOT migrated: otp_backup_codes. Keycloak's recovery-code format differs and
# there is no clean partialImport mapping, so backup codes are dropped. A user
# who relied on them at first post-cutover login must use their authenticator
# app, or have an admin reset 2FA in Keycloak. (See docs/developer/keycloak-idp.md.)
#
# Configuration:
#   - Via database: Create Idp::ServiceConfig record with connector_id: 'keycloak'
#   - Via ENV: Set KEYCLOAK_API_URL, KEYCLOAK_REALM, KEYCLOAK_SERVICE_CLIENT_ID, KEYCLOAK_SERVICE_CLIENT_SECRET
#
# Usage:
#   rails keycloak:migrate_users                    # Migrate all users in batches of 50 (SKIP existing)
#   rails keycloak:migrate_users[100]               # Migrate first 100 users
#   rails keycloak:migrate_users[,25]               # Migrate all users in batches of 25
#   rails keycloak:migrate_users[,,OVERWRITE]       # Re-migrate all users, overwriting existing records
#   rails keycloak:migrate_users[,,OVERWRITE,2026-06-14T00:00] # Delta re-run: only users changed since the timestamp
#   rails keycloak:export_users                     # Export users to JSON file
#   rails keycloak:export_users[100]                # Export first 100 users
#   rails keycloak:export_users[,2026-06-14T00:00]  # Export only users changed since the timestamp
#   rails keycloak:import_users[tmp/file.json]      # Import users from JSON file
#   rails keycloak:import_single_user[test@example.com] # Import single user
#   rails keycloak:test_connection                  # Test Keycloak connection
#
# Pre-flip step: run a last migrate_users delta (pass a `since` timestamp, or
# OVERWRITE) in a brief low-traffic window immediately before the flip, so the
# migrate -> flip gap is minutes and any changes made during migration carry over.
#

# @see docs/developer/keycloak-idp.md
namespace :keycloak do
  # Build the importer, exiting unless a real Keycloak service is configured.
  def keycloak_importer
    service = Idp::ServiceFactory.for_connector('keycloak')

    unless service.is_a?(Idp::KeycloakService)
      puts 'Error: Keycloak service not configured'
      exit 1
    end

    Idp::Keycloak::UserImporter.new(service: service)
  end

  # Parse a `since` task argument into a Time, or nil when blank.
  def keycloak_since(raw)
    return nil if raw.blank?

    Time.zone.parse(raw) || (puts("Error: could not parse since: #{raw}") || exit(1))
  end

  desc 'Migrate users from Devise to Keycloak in batches'
  task :migrate_users, [:limit, :batch_size, :policy, :since] => :environment do |_t, args|
    limit = args[:limit]&.to_i
    batch_size = args[:batch_size]&.to_i || 50
    policy = args[:policy] || 'SKIP'
    since = keycloak_since(args[:since])

    importer = keycloak_importer

    users_scope = Idp::Keycloak::UserImporter.migration_scope(since: since)
    users_scope = users_scope.limit(limit) if limit

    total = users_scope.count
    processed = 0
    failed = 0

    puts "Migrating #{total} users to Keycloak in batches of #{batch_size} (policy: #{policy})..."
    puts "Delta: only users changed since #{since}" if since
    puts '-' * 80

    users_scope.find_in_batches(batch_size: batch_size) do |batch|
      batch_num = (processed / batch_size) + 1
      print "[Batch #{batch_num}] Processing #{batch.size} users... "

      result = importer.bulk_import_users(batch, policy: policy)

      if result[:success]
        processed += batch.size
        puts "OK (#{processed}/#{total})"
      else
        failed += batch.size
        puts "FAILED: #{result[:error]}"
      end
    end

    puts '-' * 80
    puts 'Migration complete!'
    puts "  Total: #{total}"
    puts "  Processed: #{processed}"
    puts "  Failed: #{failed}"
  end

  desc 'Export users from Devise to Keycloak partialImport format'
  task :export_users, [:limit, :since] => :environment do |_t, args|
    limit = args[:limit]&.to_i
    since = keycloak_since(args[:since])

    importer = keycloak_importer

    users_scope = Idp::Keycloak::UserImporter.migration_scope(since: since)
    users_scope = users_scope.limit(limit) if limit
    users = users_scope.to_a

    puts "Exporting #{users.size} users..."
    puts "Delta: only users changed since #{since}" if since
    puts '-' * 80

    import_data = importer.export_users_to_import_format(users)
    output_file = 'tmp/keycloak_users_export.json'
    File.write(output_file, JSON.pretty_generate(import_data))

    puts 'Export complete!'
    puts "  Total users: #{users.size}"
    puts "  Output file: #{output_file}"
    puts ''
    puts 'Next steps:'
    puts "  1. Review the exported file: #{output_file}"
    puts "  2. Import users: rails keycloak:import_users[#{output_file}]"
    puts "  3. Cleanup the tmp file: rm #{output_file}"
  end

  desc 'Import users to Keycloak using partialImport API'
  task :import_users, [:file] => :environment do |_t, args|
    file = args[:file] || 'tmp/keycloak_users_export.json'

    unless File.exist?(file)
      puts "Error: File not found: #{file}"
      exit 1
    end

    importer = keycloak_importer

    puts "Importing users from #{file}..."
    puts '-' * 80

    result = importer.import_from_file(file)

    if result[:success]
      puts 'Import successful!'
      puts "Response: #{result[:response]}"
    else
      puts "Import failed: #{result[:error]}"
      exit 1
    end

    puts '-' * 80
    puts 'Import complete!'
  rescue Idp::ServiceError => e
    puts "Error: #{e.message}"
    exit 1
  end

  desc 'Import a single user to Keycloak (for testing)'
  task :import_single_user, [:email] => :environment do |_t, args|
    email = args[:email]
    unless email
      puts 'Usage: rails keycloak:import_single_user[user@example.com]'
      exit 1
    end

    user = User.find_by(email: email)
    unless user
      puts "User not found: #{email}"
      exit 1
    end

    importer = keycloak_importer

    puts "Importing user: #{user.email}"
    puts "  Name: #{user.first_name} #{user.last_name}"
    puts "  Confirmed: #{user.confirmed_at.present?}"
    puts '-' * 80

    result = importer.bulk_import_users([user])

    if result[:success]
      puts 'SUCCESS!'
      puts 'User imported successfully!'
    else
      puts "FAILED: #{result[:error]}"
      exit 1
    end
  end

  desc 'Test Keycloak connection and get realm info'
  task test_connection: :environment do
    service = Idp::ServiceFactory.for_connector('keycloak')

    unless service.is_a?(Idp::KeycloakService)
      puts 'Error: Keycloak service not configured'
      exit 1
    end

    puts 'Testing Keycloak connection...'
    puts "API URL: #{ENV['KEYCLOAK_API_URL']}"
    puts '-' * 80

    result = service.test_connection

    if result[:success]
      puts 'Connection successful!'
      puts "Message: #{result[:message]}"
    else
      puts 'Connection failed!'
      puts "Message: #{result[:message]}"
      exit 1
    end

    puts '-' * 80
  end
end
