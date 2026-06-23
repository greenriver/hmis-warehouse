###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Live SFTP examples read connection settings from ENV so the same specs work locally
# (SFTP_HOST=sftp via docker compose) and in CI (SFTP_HOST=hmis-warehouse-sftp).
#
# Local: docker compose up -d sftp && dcr spec rspec spec/models/health/import_config_spec.rb
#
module SftpIntegration
  def sftp_integration_enabled?
    ENV['SFTP_HOST'].present?
  end

  def sftp_integration_import_config
    host = ENV.fetch('SFTP_HOST')
    port = ENV.fetch('SFTP_PORT', '22')

    Health::ImportConfigPassword.new(
      host: "#{host}:#{port}",
      path: ENV.fetch('SFTP_PATH', '/sftp'),
      username: ENV.fetch('SFTP_USERNAME', 'user'),
      password: ENV.fetch('SFTP_PASSWORD', 'password'),
    )
  end

  def sftp_integration_remote_dir
    File.join(
      ENV.fetch('SFTP_PATH', '/sftp'),
      'integration_tests',
      sftp_integration_run_id,
    )
  end

  def sftp_integration_run_id
    @sftp_integration_run_id ||= "#{Process.pid}-#{SecureRandom.hex(4)}"
  end

  def sftp_integration_remove_remote_paths(paths)
    return if paths.blank?

    sftp_integration_import_config.connect do |connection|
      paths.each do |path|
        connection.remove(path)
      rescue Sftp::Cli::StatusException
        # File may already be gone if the example failed mid-way.
      end
    end
  end
end

RSpec.configure do |config|
  config.include SftpIntegration, :sftp_integration

  config.before(:each, :sftp_integration) do
    skip 'SFTP integration tests require SFTP_HOST (sftp locally, hmis-warehouse-sftp in CI)' unless sftp_integration_enabled?
  end
end
