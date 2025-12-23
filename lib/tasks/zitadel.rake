# frozen_string_literal: true

###
# Rake task to migrate users from Devise to Zitadel using bulk import
#
# Usage:
#   rails zitadel:export_users                    # Export users to JSON file
#   rails zitadel:export_users[100]               # Export only 100 users for testing
#   rails zitadel:import_users[tmp/zitadel_users_export.json] # Import users from JSON file
#
# Prerequisites:
#   1. Set environment variables:
#      - ZITADEL_API_URL (e.g., http://op-zitadel.dev.test:8080)
#      - ZITADEL_SERVICE_USER_TOKEN (Personal Access Token with admin permissions)
#      - ZITADEL_ORG_ID (Your organization ID in Zitadel)
#      - ZITADEL_PROJECT_ID (Your project ID for the Warehouse application)
#

namespace :zitadel do
  desc 'Export users from Devise to Zitadel bulk import format'
  task :export_users, [:limit] => :environment do |_t, args|
    limit = args[:limit]&.to_i
    org_id = ENV.fetch('ZITADEL_ORG_ID')

    users_scope = User.where.not(confirmed_at: nil).where(active: true)
    users_scope = users_scope.limit(limit) if limit

    total = users_scope.count

    puts "Exporting #{total} users to Zitadel bulk import format..."
    puts "Organization ID: #{org_id}"
    puts '-' * 80

    # Build the bulk import structure
    human_users = []

    users_scope.find_each.with_index do |user, index|
      print "[#{index + 1}/#{total}] Processing #{user.email}... "

      human_user = {
        userId: user.id.to_s,
        user: {
          userName: user.email,
          profile: {
            firstName: user.first_name,
            lastName: user.last_name,
            displayName: "#{user.first_name} #{user.last_name}",
            preferredLanguage: 'en',
          },
          email: {
            email: user.email,
            isEmailVerified: user.confirmed_at.present?,
          },
        },
      }

      # Add phone if present
      if user.phone.present?
        human_user[:user][:phone] = {
          phone: user.phone,
          isPhoneVerified: false,
        }
      end

      # Add bcrypt password hash
      if user.encrypted_password.present?
        human_user[:user][:hashedPassword] = {
          value: user.encrypted_password,
          algorithm: 'bcrypt',
        }
      end

      # Add TOTP secret if user has 2FA enabled
      if user.encrypted_otp_secret.present?
        begin
          otp_secret = user.otp_secret
          human_user[:user][:otpCode] = otp_secret
          print '(2FA) '
        rescue StandardError => e
          # If we can't decrypt the OTP secret, skip it
          print "(2FA failed: #{e.message}) "
        end
      end

      human_users << human_user
      puts 'OK'
    end

    # Build the complete import structure
    import_data = {
      timeout: '10m',
      data_orgs: {
        orgs: [
          {
            orgId: org_id,
            humanUsers: human_users,
          },
        ],
      },
    }

    # Write to file
    output_file = 'tmp/zitadel_users_export.json'
    File.write(output_file, JSON.pretty_generate(import_data))

    puts '-' * 80
    puts 'Export complete!'
    puts "  Total users: #{total}"
    puts "  Output file: #{output_file}"
    puts ''
    puts 'Next steps:'
    puts "  1. Review the exported file: #{output_file}"
    puts "  2. Import users: rails zitadel:import_users[#{output_file}]"
  end

  desc 'Import users to Zitadel using bulk import API'
  task :import_users, [:file] => :environment do |_t, args|
    require 'net/http'
    require 'json'

    file = args[:file] || 'tmp/zitadel_users_export.json'

    unless File.exist?(file)
      puts "Error: File not found: #{file}"
      exit 1
    end

    api_url = ENV.fetch('ZITADEL_API_URL', 'http://op-zitadel.dev.test:8080')
    token = ENV.fetch('ZITADEL_SERVICE_USER_TOKEN')

    puts "Importing users from #{file}..."
    puts "API URL: #{api_url}"
    puts '-' * 80

    # Read the export file
    import_data = JSON.parse(File.read(file))
    user_count = import_data.dig('data_orgs', 'orgs', 0, 'humanUsers')&.size || 0

    puts "Found #{user_count} users to import"
    puts 'Sending bulk import request...'

    # Send to Zitadel import API
    uri = URI("#{api_url}/admin/v1/import")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'

    request = Net::HTTP::Post.new(uri.path)
    request['Authorization'] = "Bearer #{token}"
    request['Content-Type'] = 'application/json'
    request.body = import_data.to_json

    response = http.request(request)

    case response.code.to_i
    when 200..299
      puts 'SUCCESS!'
      puts "Response: #{response.body}"

      # Parse response to get details
      result = JSON.parse(response.body)
      puts ''
      puts 'Import summary:'
      puts "  Status: #{result['status'] || 'completed'}"
    when 400..499
      puts "CLIENT ERROR: #{response.code}"
      puts "Response: #{response.body}"
      exit 1
    when 500..599
      puts "SERVER ERROR: #{response.code}"
      puts "Response: #{response.body}"
      exit 1
    else
      puts "UNEXPECTED RESPONSE: #{response.code}"
      puts "Response: #{response.body}"
      exit 1
    end

    puts '-' * 80
    puts 'Import complete!'
  end

  desc 'Import a single user to Zitadel (for testing)'
  task :import_single_user, [:email] => :environment do |_t, args|
    require 'net/http'
    require 'json'

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

    api_url = ENV.fetch('ZITADEL_API_URL', 'http://op-zitadel.dev.test:8080')
    token = ENV.fetch('ZITADEL_SERVICE_USER_TOKEN')
    org_id = ENV.fetch('ZITADEL_ORG_ID')

    puts "Importing user: #{user.email}"
    puts "  Name: #{user.first_name} #{user.last_name}"
    puts "  Confirmed: #{user.confirmed_at.present?}"
    puts '-' * 80

    # Build user data
    user_data = {
      userName: user.email,
      profile: {
        firstName: user.first_name,
        lastName: user.last_name,
        displayName: "#{user.first_name} #{user.last_name}",
        preferredLanguage: 'en',
      },
      email: {
        email: user.email,
        isEmailVerified: user.confirmed_at.present?,
      },
    }

    # Add phone if present
    if user.phone.present?
      user_data[:phone] = {
        phone: user.phone,
        isPhoneVerified: false,
      }
    end

    # Add bcrypt password hash
    if user.encrypted_password.present?
      user_data[:hashedPassword] = {
        value: user.encrypted_password,
        algorithm: 'bcrypt',
      }
    end

    # Add TOTP secret if user has 2FA enabled
    if user.encrypted_otp_secret.present?
      begin
        otp_secret = user.otp_secret
        user_data[:otpCode] = otp_secret
        puts '  2FA: Enabled (will be migrated)'
      rescue StandardError => e
        puts "  2FA: Enabled (but failed to decrypt: #{e.message})"
      end
    end

    # Send to Zitadel ImportHumanUser API
    uri = URI("#{api_url}/management/v1/users/human/_import")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'

    request = Net::HTTP::Post.new(uri.path)
    request['Authorization'] = "Bearer #{token}"
    request['Content-Type'] = 'application/json'
    request['x-zitadel-orgid'] = org_id
    request.body = user_data.to_json

    puts "Sending request to #{uri}..."
    response = http.request(request)

    case response.code.to_i
    when 200..299
      puts 'SUCCESS!'
      result = JSON.parse(response.body)
      puts "  Zitadel User ID: #{result['userId']}"
      puts ''
      puts 'User imported successfully!'
    when 400..499
      puts "CLIENT ERROR: #{response.code}"
      puts "Response: #{response.body}"
    when 500..599
      puts "SERVER ERROR: #{response.code}"
      puts "Response: #{response.body}"
    else
      puts "UNEXPECTED RESPONSE: #{response.code}"
      puts "Response: #{response.body}"
    end
  end

  desc 'Test Zitadel connection and get organization info'
  task test_connection: :environment do
    require 'net/http'
    require 'json'

    api_url = ENV.fetch('ZITADEL_API_URL', 'http://op-zitadel.dev.test:8080')
    token = ENV.fetch('ZITADEL_SERVICE_USER_TOKEN')

    puts 'Testing Zitadel connection...'
    puts "API URL: #{api_url}"
    puts '-' * 80

    # Try to get current organization
    uri = URI("#{api_url}/management/v1/orgs/me")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'

    request = Net::HTTP::Get.new(uri.path)
    request['Authorization'] = "Bearer #{token}"

    response = http.request(request)

    case response.code.to_i
    when 200..299
      puts 'Connection successful!'
      result = JSON.parse(response.body)
      puts ''
      puts 'Organization info:'
      puts "  ID: #{result.dig('org', 'id')}"
      puts "  Name: #{result.dig('org', 'name')}"
      puts "  Primary Domain: #{result.dig('org', 'primaryDomain')}"
    else
      puts "Connection failed: #{response.code}"
      puts "Response: #{response.body}"
      exit 1
    end
  end
end
