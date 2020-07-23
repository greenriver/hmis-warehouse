###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Encryption
  class SecretRotation
    SECRET_ID = ENV.fetch('ENCRYPTION_SECRET_ARN') { 'disabled' }
    KEY_LENGTH = 32

    attr_accessor :secret

    def initialize(secret)
      self.secret = secret
    end

    def run!(first_try: true, &block)
      raise "Cannot rotate non-current" unless secret.current?

      payload = {
        'encryption_key': SecureRandom.hex(KEY_LENGTH / 2)
      }

      response = _client.put_secret_value({
        secret_id: SECRET_ID,
        secret_string: payload.to_json,
        version_stages: [
          new_version,
          'AWSCURRENT'
        ]
      })
      new_version_id = response.version_id

      Secret.transaction do
        Secret.update_all(previous: false)
        Secret.update_all(current: false)

        secret.update!({
          previous: true,
          current: false,
          rotated_at: Time.now
        })

        new_secret = Secret.create!({
          current: true,
          previous: false,
          version_stage: new_version,
          version_id: new_version_id,
        })

        if block_given?
          block.call(secret, new_secret)
        end
      end
    rescue Aws::SecretsManager::Errors::LimitExceededException => e
      raise e unless first_try
      Rails.logger.warn "[PII] Pruning some stages and trying again"
      Util.prune!(5)
      run!(&block)
    end

    def new_version
      @new_version ||= Date.today.to_s(:iso) + "_" + SecureRandom.hex(3)
    end

    private

    def _client
      @_client ||= Aws::SecretsManager::Client.new
    end
  end
end
