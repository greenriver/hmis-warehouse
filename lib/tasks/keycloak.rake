# frozen_string_literal: true

###
# Rake tasks for Keycloak IDP user migration and management
#
# Tasks use the centralized Idp::KeycloakService for all API communication.
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
#   rails keycloak:export_users                     # Export users to JSON file
#   rails keycloak:export_users[100]                # Export first 100 users
#   rails keycloak:import_users[tmp/file.json]      # Import users from JSON file
#   rails keycloak:import_single_user[test@example.com] # Import single user
#   rails keycloak:test_connection                  # Test Keycloak connection
#

# @see docs/developer/keycloak-idp.md
namespace :keycloak do
  desc 'Migrate users from Devise to Keycloak in batches'
  task :migrate_users, [:limit, :batch_size, :policy] => :environment do |_t, args|
    limit = args[:limit]&.to_i
    batch_size = args[:batch_size]&.to_i || 50
    policy = args[:policy] || 'SKIP'

    service = Idp::ServiceFactory.for_connector('keycloak')

    unless service.is_a?(Idp::KeycloakService)
      puts 'Error: Keycloak service not configured'
      exit 1
    end

    users_scope = User.where.not(confirmed_at: nil).where(active: true)
    users_scope = users_scope.limit(limit) if limit

    total = users_scope.count
    processed = 0
    failed = 0

    puts "Migrating #{total} users to Keycloak in batches of #{batch_size} (policy: #{policy})..."
    puts '-' * 80

    users_scope.find_in_batches(batch_size: batch_size) do |batch|
      batch_num = (processed / batch_size) + 1
      print "[Batch #{batch_num}] Processing #{batch.size} users... "

      result = service.bulk_import_users(batch, policy: policy)

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
  task :export_users, [:limit] => :environment do |_t, args|
    limit = args[:limit]&.to_i
    service = Idp::ServiceFactory.for_connector('keycloak')

    users_scope = User.where.not(confirmed_at: nil).where(active: true)
    users_scope = users_scope.limit(limit) if limit
    users = users_scope.to_a

    puts "Exporting #{users.size} users..."
    puts '-' * 80

    import_data = service.export_users_to_import_format(users)
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

    service = Idp::ServiceFactory.for_connector('keycloak')

    puts "Importing users from #{file}..."
    puts '-' * 80

    result = service.import_from_file(file)

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

    service = Idp::ServiceFactory.for_connector('keycloak')

    puts "Importing user: #{user.email}"
    puts "  Name: #{user.first_name} #{user.last_name}"
    puts "  Confirmed: #{user.confirmed_at.present?}"
    puts '-' * 80

    result = service.bulk_import_users([user])

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
