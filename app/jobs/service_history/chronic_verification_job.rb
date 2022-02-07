###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ServiceHistory
  class ChronicVerificationJob < BaseJob
    include ArelHelper
    include Rails.application.routes.url_helpers
    queue_as ENV.fetch('DJ_SHORT_QUEUE_NAME', :short_running)

    def perform(client_id:, years:)
      @client_id = client_id
      @years = years
      app = ActionDispatch::Integration::Session.new(Rails.application)

      options = {
        client_id: @client_id,
        years: @years,
        host: ENV['FQDN'],
        protocol: 'https',
      }
      app.get(pdf_client_history_url(options))
    end

    def max_attempts
      2
    end
  end
end
