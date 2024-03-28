###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class ImportConfig < HealthBase
    self.table_name = :import_configs

    # Password for remote service
    attr_encrypted :password, key: ENV['ENCRYPTION_KEY'][0..31]

    # GPG secrets
    attr_encrypted :passphrase, key: ENV['ENCRYPTION_KEY'][0..31]
    attr_encrypted :secret_key, key: ENV['ENCRYPTION_KEY'][0..31]

    scope :epic_data, -> do
      where(kind: :epic_data)
    end

    def decrypt(data)
      store_secret_key
      # TODO:decrypt data
      crypto = GPGME::Crypto.new
      crypto.decrypt(data, passphrase_callback: method(:passfunc)) # FIXME: passphrase isn't working
    end

    private def store_secret_key
      GPGME::Key.import(secret_key) unless GPGME::Key.find(encryption_key_name).present?
    end

    private def passfunc(_hook, _uid_hint, _passphrase_info, _prev_was_bad, fd) # rubocop:disable Naming/MethodParameterName
      io = IO.for_fd(fd, 'w')
      io.puts(passphrase)
    end

    # TODO: This class should be STI instead
    def get(remote, local)
      raise 'Not implemented' unless kind.to_s == 'medicaid_hmis_exchange'

      connect do |connection|
        connection.download!(remote, local)
      end
    end

    def put(local, remote)
      raise 'Not implemented' unless kind.to_s == 'medicaid_hmis_exchange'

      connect do |connection|
        connection.upload!(local, remote)
      end
    end

    def ls(remote)
      raise 'Not implemented' unless kind.to_s == 'medicaid_hmis_exchange'

      connect do |connection|
        connection.dir.foreach(remote) do |entry|
          puts entry.longname
        end
      end
    end

    def connect
      raise 'Not implemented' unless kind.to_s == 'medicaid_hmis_exchange'

      file = Tempfile.new('mhx_private_key')
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
