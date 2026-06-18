###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Health
  class ImportConfigPassword < ImportConfig
    def connect
      Sftp::Cli.start(
        host_name,
        username,
        password: password,
        port: port_number,
        skip_verify_host_key: true,
      ) do |connection|
        yield connection
      end
    end
  end
end
