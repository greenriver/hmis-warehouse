###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'net/sftp'

# NOTE: this class appears unused at this time.  If we switch to key-based authentication, this should be updated to use Sftp::Cli.  Sftp::Cli may also need updates to support key-based authentication.
module Health
  class ImportConfigSsh < ImportConfig
    def connect
      file = Tempfile.new('ssh_private_key')
      key = password
      file.write(key)
      file.close

      Net::SFTP.start(
        host_name,
        username,
        keepalive: true,
        keepalive_interval: 60,
        keys: [file.path],
        keys_only: true,
        port: port_number,
        append_all_supported_algorithms: true,
      ) do |connection|
        yield connection
      end
      file.unlink
    end
  end
end
