# frozen_string_literal: true

require 'progress_bar'

###
# One-time Devise -> Keycloak user migration. Temporary, human-run, console-only
# tooling — run per Deployment before that Deployment switches to JWT auth.
# Nothing here runs on boot or in a request. Delete alongside
# Idp::Keycloak::UserImporter once all account data has been migrated.
#
# Drives Idp::Keycloak::UserImporter over Idp::KeycloakService#partial_import.
# Scope, credential handling, and the otp_backup_codes omission are documented on
# the importer and in docs/developer/keycloak-user-migration.md.
#
# Configuration (either source):
#   - DB:  an Idp::ServiceConfig record with connector_id: 'keycloak'
#   - ENV: KEYCLOAK_API_URL, KEYCLOAK_REALM, KEYCLOAK_SERVICE_CLIENT_ID, KEYCLOAK_SERVICE_CLIENT_SECRET
#
# Usage:
#   rails keycloak:migrate_users                     # all users, batches of 50, OVERWRITE existing
#   rails keycloak:migrate_users[100]                # first 100 users
#   rails keycloak:migrate_users[,25]                # batches of 25
#   rails keycloak:migrate_users[,,SKIP]             # leave users that already exist untouched
#   rails keycloak:migrate_users[,,OVERWRITE,2026-06-14T00:00]  # re-import only users changed since
#   rails keycloak:export_users[100,2026-06-14T00:00]  # write JSON instead of importing
#   rails keycloak:import_users[tmp/file.json]       # import a previously exported file
#   rails keycloak:import_single_user[a@example.com] # import one user (testing)
#   rails keycloak:test_connection
#
# OVERWRITE is the default so a re-run carries over edits (e.g. a password the
# user changed after the first pass) instead of silently skipping them. The
# intended pre-flip step is a final pass — optionally with a `since` timestamp —
# in a low-traffic window, keeping the switchover gap to minutes.
###

# @see docs/developer/keycloak-user-migration.md
namespace :keycloak do
  # Build the importer, exiting unless a real Keycloak service is configured.
  def keycloak_importer
    service = Idp::ServiceFactory.for_connector('keycloak')

    unless service.is_a?(Idp::KeycloakService)
      warn 'Error: Keycloak service not configured'
      exit 1
    end

    Idp::Keycloak::UserImporter.new(service: service)
  end

  # Parse a `since` task argument into a Time, or nil when blank.
  def keycloak_since(raw)
    return nil if raw.blank?

    Time.zone.parse(raw) || (warn("Error: could not parse since: #{raw}") || exit(1))
  end

  # Refuse to build credentials under AUTH_METHOD=jwt. Building a TOTP credential
  # reads User#otp_secret, an accessor the :two_factor_authenticatable Devise
  # macro provides only in devise mode (UserConcern gates the macro behind
  # AuthMethod.devise?).
  #
  def keycloak_assert_devise!
    return if AuthMethod.devise?

    warn 'Error: keycloak user migration requires AUTH_METHOD=devise (Devise credential accessors such as User#otp_secret are disabled under jwt). Re-run prefixed with AUTH_METHOD=devise, e.g. AUTH_METHOD=devise bin/rails keycloak:migrate_users'
    exit 1
  end

  desc 'Migrate users from Devise to Keycloak in batches'
  task :migrate_users, [:limit, :batch_size, :policy, :since] => :environment do |_t, args|
    limit = args[:limit]&.to_i
    batch_size = args[:batch_size]&.to_i || 50
    policy = args[:policy] || 'OVERWRITE'
    since = keycloak_since(args[:since])

    keycloak_assert_devise!
    importer = keycloak_importer

    users_scope = Idp::Keycloak::UserImporter.migration_scope(since: since)
    users_scope = users_scope.limit(limit) if limit

    total = users_scope.count
    added = 0
    overwritten = 0
    skipped = 0
    failed = 0
    batch_num = 0

    bar = ProgressBar.new(total, :counter, :bar, :percentage, :rate, :eta)
    bar.puts "Migrating #{total} users to Keycloak in batches of #{batch_size} (policy: #{policy})..."
    bar.puts "Delta: only users changed since #{since}" if since

    users_scope.find_in_batches(batch_size: batch_size) do |batch|
      batch_num += 1
      result = importer.bulk_import_users(batch, policy: policy)

      if result[:success]
        added += result[:added].to_i
        overwritten += result[:overwritten].to_i
        skipped += result[:skipped].to_i
        bar.puts "[Batch #{batch_num}] OK (added #{result[:added].to_i}, overwritten #{result[:overwritten].to_i}, skipped #{result[:skipped].to_i})"
      else
        failed += batch.size
        bar.puts "[Batch #{batch_num}] FAILED: #{result[:error]}"
      end
      bar.increment!(batch.size)
    end

    bar.puts 'Migration complete!'
    bar.puts "  In scope:    #{total}"
    bar.puts "  Added:       #{added}"
    bar.puts "  Overwritten: #{overwritten}"
    bar.puts "  Skipped:     #{skipped}"
    bar.puts "  Failed:      #{failed}"
    exit 1 if failed.positive?
  end

  desc 'Export users from Devise to Keycloak partialImport format'
  task :export_users, [:limit, :since] => :environment do |_t, args|
    limit = args[:limit]&.to_i
    since = keycloak_since(args[:since])

    keycloak_assert_devise!
    importer = keycloak_importer

    users_scope = Idp::Keycloak::UserImporter.migration_scope(since: since)
    users_scope = users_scope.limit(limit) if limit
    users = users_scope.to_a

    bar = ProgressBar.new(users.count, :counter, :bar, :percentage)
    bar.puts "Exporting #{users.size} users..."
    bar.puts "Delta: only users changed since #{since}" if since

    # OVERWRITE matches migrate_users; edit the file before importing to change it.
    import_data = importer.export_users_to_import_format(users, policy: 'OVERWRITE', progress: bar)

    output_file = 'tmp/keycloak_users_export.json'
    File.open(output_file, 'w', 0o600) { |f| f.write(JSON.pretty_generate(import_data)) }

    bar.puts 'Export complete!'
    bar.puts "  Total users: #{users.size}"
    bar.puts "  Output file: #{output_file}"
    bar.puts ''
    bar.puts 'Next steps:'
    bar.puts "  1. Review the exported file: #{output_file}"
    bar.puts "  2. Import users: rails keycloak:import_users[#{output_file}]"
    bar.puts "  3. Cleanup the tmp file: rm #{output_file}"
  end

  desc 'Import users to Keycloak using partialImport API'
  task :import_users, [:file] => :environment do |_t, args|
    file = args[:file] || 'tmp/keycloak_users_export.json'

    unless File.exist?(file)
      warn "Error: File not found: #{file}"
      exit 1
    end

    importer = keycloak_importer

    puts "Importing users from #{file}..."

    # import_from_file returns on success and raises Idp::ServiceError otherwise.
    result = importer.import_from_file(file)

    puts 'Import successful!'
    puts "Response: #{result[:response]}"
    puts 'Import complete!'
  rescue Idp::ServiceError => e
    puts "Error: #{e.message}"
    exit 1
  end

  desc 'Import a single user to Keycloak (for testing)'
  task :import_single_user, [:email] => :environment do |_t, args|
    keycloak_assert_devise!

    email = args[:email]
    unless email
      warn 'Usage: rails keycloak:import_single_user[user@example.com]'
      exit 1
    end

    user = User.find_by(email: email)
    unless user
      warn "User not found: #{email}"
      exit 1
    end

    importer = keycloak_importer

    puts "Importing user: #{user.email}"
    puts "  Name: #{user.first_name} #{user.last_name}"
    puts "  Confirmed: #{user.confirmed_at.present?}"

    result = importer.bulk_import_users([user], policy: 'OVERWRITE')

    if result[:success]
      puts 'SUCCESS! User imported successfully!'
    else
      puts "FAILED: #{result[:error]}"
      exit 1
    end
  end

  desc 'Test Keycloak connection and get realm info'
  task test_connection: :environment do
    service = Idp::ServiceFactory.for_connector('keycloak')

    unless service.is_a?(Idp::KeycloakService)
      warn 'Error: Keycloak service not configured'
      exit 1
    end

    puts 'Testing Keycloak connection...'
    puts "API URL: #{ENV['KEYCLOAK_API_URL']}"

    result = service.test_connection

    if result[:success]
      puts 'Connection successful!'
      puts "Message: #{result[:message]}"
    else
      puts 'Connection failed!'
      puts "Message: #{result[:message]}"
      exit 1
    end
  end
end
