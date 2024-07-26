###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class ImportConfigSsh < ImportConfig
    def connect
      raise 'Not implemented' unless kind.to_s == 'medicaid_hmis_exchange'

      file = Tempfile.new('ssh_private_key')
      opts = {
        keepalive: true,
        keepalive_interval: 60,
      }
      if Rails.env.production? || Rails.env.staging?
        key = password
        file.write(key)
        file.rewind
        file.close
        opts.merge!(
          {
            keys: [file.path],
            keys_only: true,
          },
        )

      else
        opts.merge!(
          {
            password: password,
            auth_methods: ['publickey', 'password'],
          },
        )
      end

      Net::SFTP.start(
        host,
        username,
        **opts,
      ) do |connection|
        yield connection
      end
      file.unlink
    end
  end
end
