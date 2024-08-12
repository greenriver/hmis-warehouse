###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ServiceHistory
  class ChronicVerificationJob < BaseJob
    include ArelHelper
    include Rails.application.routes.url_helpers
    queue_as ENV.fetch('DJ_SHORT_QUEUE_NAME', :short_running)

    def perform(client_id:, years:, user_id: nil)
      client_history = ClientHistory.new(client_id: client_id, years: years, user_id: user_id)
      client_history.generate_service_history_pdf
    end

    def max_attempts
      2
    end
  end
end
