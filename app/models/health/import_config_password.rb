###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class ImportConfigPassword < ImportConfig
    def connect
      Net::SFTP.start(
        host,
        username,
        password: password,
        # verbose: :debug,
        auth_methods: ['publickey', 'password'],
      ) do |connection|
        yield connection
      end
    end
  end
end
