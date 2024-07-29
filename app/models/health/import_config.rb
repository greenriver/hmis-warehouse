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

    def decrypt_data(data)
      store_secret_key

      crypto = GPGME::Crypto.new
      options = {
        pinentry_mode: GPGME::PINENTRY_MODE_LOOPBACK,
        password: passphrase,
      }
      crypto.decrypt(data, options).to_s
    end

    private def store_secret_key
      GPGME::Key.import(secret_key) unless GPGME::Key.find(encryption_key_name).present?
    end

    private def host_name
      host.split(':').first
    end

    private def port_number
      _, port = host.split(':')

      if port.present?
        port.to_i
      else
        22
      end
    end

    def get(remote, local, recursive: false)
      connect do |connection|
        connection.download!(remote, local, recursive: recursive)
      end
    end

    def put(local, remote)
      connect do |connection|
        connection.upload!(local, remote)
      end
    end

    def ls(remote)
      connect do |connection|
        connection.dir.foreach(remote) do |entry|
          puts entry.longname
        end
      end
    end
  end
end
