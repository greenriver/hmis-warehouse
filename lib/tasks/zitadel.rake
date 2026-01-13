# frozen_string_literal: true

###
# Rake tasks for Zitadel IDP user migration and management
#
# Tasks use the centralized Idp::ZitadelService for all API communication.
#
# Configuration:
#   - Via database: Create Idp::ServiceConfig record with connector_id: 'zitadel'
#   - Via ENV: Set ZITADEL_API_URL, ZITADEL_SERVICE_USER_TOKEN, ZITADEL_ORG_ID, ZITADEL_PROJECT_ID
#
# Usage:
#   rails zitadel:migrate_users                    # Migrate all users in batches of 50
#   rails zitadel:migrate_users[100]               # Migrate first 100 users
#   rails zitadel:migrate_users[,25]               # Migrate all users in batches of 25
#   rails zitadel:export_users                     # Export users to JSON file
#   rails zitadel:export_users[100]                # Export first 100 users
#   rails zitadel:import_users[tmp/file.json]      # Import users from JSON file
#   rails zitadel:import_single_user[test@example.com] # Import single user
#   rails zitadel:test_connection                  # Test Zitadel connection
#

namespace :zitadel do
  desc 'Migrate users from Devise to Zitadel in batches'
  task :migrate_users, [:limit, :batch_size] => :environment do |_t, args|
    limit = args[:limit]&.to_i
    batch_size = args[:batch_size]&.to_i || 50

    service = Idp::ServiceFactory.for_connector('zitadel')

    unless service.is_a?(Idp::ZitadelService)
      puts 'Error: Zitadel service not configured'
      exit 1
    end

    users_scope = User.where.not(confirmed_at: nil).where(active: true)
    users_scope = users_scope.limit(limit) if limit

    total = users_scope.count
    processed = 0
    failed = 0

    puts "Migrating #{total} users to Zitadel in batches of #{batch_size}..."
    puts "Organization ID: #{ENV['ZITADEL_ORG_ID']}"
    puts '-' * 80

    users_scope.find_in_batches(batch_size: batch_size) do |batch|
      batch_num = (processed / batch_size) + 1
      print "[Batch #{batch_num}] Processing #{batch.size} users... "

      result = service.bulk_import_users(batch)

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

  desc 'Export users from Devise to Zitadel bulk import format'
  task :export_users, [:limit] => :environment do |_t, args|
    limit = args[:limit]&.to_i
    service = Idp::ServiceFactory.for_connector('zitadel')

    users_scope = User.where.not(confirmed_at: nil).where(active: true)
    users_scope = users_scope.limit(limit) if limit
    users = users_scope.to_a

    puts "Exporting #{users.size} users..."
    puts '-' * 80

    import_data = service.export_users_to_import_format(users)
    output_file = 'tmp/zitadel_users_export.json'
    File.write(output_file, JSON.pretty_generate(import_data))

    puts 'Export complete!'
    puts "  Total users: #{users.size}"
    puts "  Output file: #{output_file}"
    puts ''
    puts 'Next steps:'
    puts "  1. Review the exported file: #{output_file}"
    puts "  2. Import users: rails zitadel:import_users[#{output_file}]"
    puts "  3. Cleanup the tmp file: rm #{output_file}"
  end

  desc 'Import users to Zitadel using bulk import API'
  task :import_users, [:file] => :environment do |_t, args|
    file = args[:file] || 'tmp/zitadel_users_export.json'

    unless File.exist?(file)
      puts "Error: File not found: #{file}"
      exit 1
    end

    service = Idp::ServiceFactory.for_connector('zitadel')

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

  desc 'Import a single user to Zitadel (for testing)'
  task :import_single_user, [:email] => :environment do |_t, args|
    email = args[:email]
    unless email
      puts 'Usage: rails zitadel:import_single_user[user@example.com]'
      exit 1
    end

    user = User.find_by(email: email)
    unless user
      puts "User not found: #{email}"
      exit 1
    end

    service = Idp::ServiceFactory.for_connector('zitadel')

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

  desc 'Test Zitadel connection and get organization info'
  task test_connection: :environment do
    service = Idp::ServiceFactory.for_connector('zitadel')

    puts 'Testing Zitadel connection...'
    puts "API URL: #{ENV['ZITADEL_API_URL']}"
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
