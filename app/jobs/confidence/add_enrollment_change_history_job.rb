module Confidence
  class AddEnrollmentChangeHistoryJob < BaseJob
    queue_as :low_priority

    def perform client_ids:, date:
      @client_ids = client_ids
      @date = date.to_date
      GrdaWarehouse::EnrollmentChangeHistory.create_for_clients_on_date! client_ids: @client_ids, date: @date
    end

    def max_attempts
      1
    end

  end
end