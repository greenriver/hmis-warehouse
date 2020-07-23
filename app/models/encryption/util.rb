###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Encryption
  class Util
    SECRET_ID = ENV.fetch('ENCRYPTION_SECRET_ARN') { 'disabled' }

    def self.encryption_disabled?
      SECRET_ID.blank? || !SECRET_ID.starts_with?('arn:aws:secretsmanager:')
    end

    def self.encryption_enabled?
      !encryption_disabled?
    end

    # Run once to get an empty secret if you need it
    def self.bootstrap!
      default_name = [
        ENV.fetch('CLIENT') { 'unknown-client' },
        'warehouse',
        Rails.env,
        'encryption-data',
      ].join('--').downcase.gsub(/[^a-z0-9-]/, '-')

      response = _client.create_secret({
        name: default_name,
      })

      ap response.arn
    end

    def self.init!
      return if Secret.count > 1

      # To reduce complexity, the first entry is not an actual secret. This
      # prevents needing code that only runs the first time (beyond this simple
      # method of course)
      secret = Secret.where({
        version_stage: 'bootstrap-do-not-use',
        version_id: 'bootstrap-do-not-use'
      }).first_or_initialize

      secret.update!({
        current: true,
        previous: false,
      })

      Secret.current.rotate!
    end

    def self.history
      response = _client.list_secret_version_ids({
        secret_id: SECRET_ID,
      })
      versions = []
      response.each do |batch|
        versions += batch.versions
      end

      versions.sort_by! { |x| x.created_date }

      versions
    end

    def self.prune!(limit=50)
      count = 0
      history.each do |version|
        version.version_stages.each do |stage|
          if ['AWSCURRENT', 'AWSPREVIOUS'].exclude?(stage)
            _client.update_secret_version_stage({
              secret_id: SECRET_ID,
              version_stage: stage,
              remove_from_version_id: version.version_id,
            })
            count += 1
          end

          return if count == limit
        end
      end
    end

    def self.get_key(version_id)
      resp = _client.get_secret_value({
        secret_id: SECRET_ID,
        version_id: version_id,
      })
      JSON.parse(resp.secret_string)['encryption_key']
    rescue Aws::Errors::ServiceError
      Rails.logger.error "[PII] Could not get the secret requested and thus get the encryption key"
      'secret-not-found'
    end

    private

    def self._client
      @_client ||= Aws::SecretsManager::Client.new
    end
  end
end
