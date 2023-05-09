###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Confidence
  class AddEnrollmentChangeHistoryJob < BaseJob
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    def perform(client_ids:, date:)
      @client_ids = client_ids
      @date = date.to_date
      GrdaWarehouse::EnrollmentChangeHistory.create_for_clients_on_date! client_ids: @client_ids, date: @date
    end

    def max_attempts
      1
    end
  end
end
