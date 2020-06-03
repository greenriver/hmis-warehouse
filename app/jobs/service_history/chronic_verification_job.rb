###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module ServiceHistory
  class ChronicVerificationJob < BaseJob
    include ArelHelper
    include Rails.application.routes.url_helpers
    queue_as :short_running

    def initialize(client_id:, years:)
      @client_id = client_id
      @years = years
    end

    def perform
      app = ActionDispatch::Integration::Session.new(Rails.application)

      options = {
        client_id: @client_id,
        years: @years,
        host: ENV['FQDN'],
        protocol: 'https',
      }
      app.get(pdf_window_client_history_url(options))
    end

    def enqueue(job, queue: :short_running)
    end

    def max_attempts
      2
    end
  end
end
