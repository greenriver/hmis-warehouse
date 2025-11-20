###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'net/sftp'

module Health
  class ImportConfigPassword < ImportConfig
    def connect
      Net::SFTP.start(
        host_name,
        username,
        password: password,
        encryption: ['chacha20-poly1305@openssh.com'],
        # verbose: :debug,
        port: port_number,
        auth_methods: ['password'],
      ) do |connection|
        yield connection
      end
    end
  end
end
