###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Developer utilities for moving files into and out of Secure Files.
# Secure Files can be accessed via the warehouse UI (Account => Secure Files) with appropriate permissions.
namespace :secure_files do
  # Uploads a local file as a SecureFile.
  # Useful for getting ad-hoc exports, reports, or data dumps into the warehouse
  # without one-off scp file transfers or manual S3 uploads.
  #
  # Only for uploading to your own greenriver account. Out of caution,
  # the task will fail if the user ID provided is not associated with a greenriver account.
  #
  # Examples:
  #   bundle exec rake "secure_files:upload_to_secure_files[/tmp/data.zip,1]"
  #
  desc 'Upload a local file as a SecureFile. Args: filepath, user_id (sender and recipient)'
  task :upload_to_secure_files, [:filepath, :user_id] => :environment do |_task, args|
    filepath = args[:filepath]
    user_id = args[:user_id]

    abort 'Usage: rake "secure_files:upload_to_secure_files[filepath,user_id]"' if filepath.blank? || user_id.blank?

    path = Pathname.new(filepath).expand_path
    abort "File not found: #{path}" unless path.file?

    user = User.find(user_id)

    # Don't allow uploading to non-greenriver accounts, to prevent accidental data exposure. If sharing externally, download and re-upload to Secure Files interface.
    raise ArgumentError, "User #{user.id} (#{user.email.inspect}) must have an email containing 'greenriver'" unless user.email&.match?(/@greenriver/i) || Rails.env.development?

    secure_file = GrdaWarehouse::SecureFile.create!(
      sender_id: user.id,
      recipient_id: user.id,
      name: path.basename.to_s,
    )

    content_type = Marcel::MimeType.for(path, name: path.basename.to_s) || 'application/octet-stream'

    File.open(path, 'rb') do |io|
      secure_file.secure_file.attach(
        io: io,
        filename: path.basename.to_s,
        content_type: content_type,
      )
    end

    puts "Created SecureFile id=#{secure_file.id}"
    puts "  name: #{secure_file.name}"
    puts "  user: #{user.id} (#{user.email})"
    puts "  size: #{secure_file.secure_file.byte_size} bytes"
    puts "  url:  https://#{ENV['FQDN']}/secure_files"
  end

  # Downloads the most recent unexpired SecureFile with a given name to var/.
  # Pass dry_run to confirm the file exists and see its size without downloading it.
  #
  # Examples:
  #   bundle exec rake "secure_files:download_from_secure_files[data.zip,true]"
  #   bundle exec rake "secure_files:download_from_secure_files[data.zip]"
  #
  desc 'Download the most recent unexpired SecureFile with a given name to var/. Args: filename, dry_run (true/false, default false)'
  task :download_from_secure_files, [:filename, :dry_run] => :environment do |_task, args|
    filename = args[:filename]
    dry_run = ['true', '1'].include?(args[:dry_run])

    abort 'Usage: rake "secure_files:download_from_secure_files[filename,dry_run]"' if filename.blank?

    secure_file = GrdaWarehouse::SecureFile.unexpired.where(name: filename).order(created_at: :desc).first
    abort "No unexpired SecureFile found with name: #{filename}" unless secure_file&.secure_file&.attached?

    if dry_run
      puts "Found SecureFile id=#{secure_file.id}"
      puts "  name: #{secure_file.name}"
      puts "  size: #{secure_file.secure_file.byte_size} bytes"
      next
    end

    dest = Rails.root.join('var', filename)
    File.open(dest, 'wb') { |f| f.write(secure_file.secure_file.download) }

    puts "Downloaded to #{dest}"
    puts "  size: #{secure_file.secure_file.byte_size} bytes"
    puts "REMINDER: delete #{dest} when you're done with it."
  end
end
