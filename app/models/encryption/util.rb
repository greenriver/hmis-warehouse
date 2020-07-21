###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Encryption
  class Util
    SECRET_ID = ENV.fetch('ENCRYPTION_SECRET_ARN') { 'disabled' }

    def self.encryption_enabled?
      new.encryption_enabled?
    end

    # Run once to get an empty secret if you need it
    def bootstrap!
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

    def init!
      return unless Secret.count == 0

      # To reduce complexity, the first entry is not an actual secret. This
      # prevents needing code that only runs the first time (beyond this simple
      # method of course)
      Secret.create!({
        current: true,
        previous: false,
        version_stage: 'bootstrap-do-not-use',
        version_id: 'bootstrap-do-not-use'
      })

      Secret.current.rotate!
    end

    def history
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

    def prune!(limit=50)
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

    def get_key(version_id)
      resp = _client.get_secret_value({
        secret_id: SECRET_ID,
        version_id: version_id,
      })
      JSON.parse(resp.secret_string)['encryption_key']
    rescue Aws::Errors::SeviceError
      Rails.logger.error "Could not get secret requested"
      'secret-not-found'
    end

    # TDB: FIXME: make this dynamic so we can turn off for most specs
    def encryption_disabled?
      SECRET_ID == 'disabled' || SECRET_ID.blank?
    end

    def encryption_enabled?
      !encryption_disabled?
    end

    private

    def _client
      @_client ||= Aws::SecretsManager::Client.new
    end
  end
end
