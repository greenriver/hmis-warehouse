###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Developer utility for uploading a file to Secure Files.
# Uploaded files can be accessed via the warehouse UI (Account => Secure Files) with appropriate permissions.
# Useful for getting ad-hoc exports, reports, or data dumps into the warehouse
# without one-off scp file transfers or manual S3 uploads.
#
# Only for uploading to your own greenriver account. Out of caution,
# the task will fail if the user ID provided is not associated with a greenriver account.
#
# Examples:
#   bundle exec rake "secure_files:upload_to_secure_files[/tmp/data.zip,1]"
#
namespace :secure_files do
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
end
