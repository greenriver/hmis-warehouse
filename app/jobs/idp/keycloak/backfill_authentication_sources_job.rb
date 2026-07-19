###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Idp
  module Keycloak
    class BackfillAuthenticationSourcesJob < BaseJob
      queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

      def perform
        with_lock do
          instrument_as_maintenance_task(name: 'Backfill Keycloak authentication sources') do |run|
            Idp::ServiceConfig.active.find_each do |config|
              service = config.to_service
              next unless service.supports_account_backfill?

              result = AuthenticationSourceBackfill.call(service: service, connector_id: config.connector_id)
              Rails.logger.info(result.summary)
            end
            run.complete!
          end
        end
      end

      protected def with_lock(&block)
        GrdaWarehouseBase.with_advisory_lock('BackfillAuthenticationSourcesJob', timeout_seconds: 0, &block)
      end
    end
  end
end
