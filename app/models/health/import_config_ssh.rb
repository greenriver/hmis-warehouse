###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
require 'net/sftp'

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
