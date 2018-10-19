module Confidence
  class AddEnrollmentChangeHistoryJob < BaseJob

    def initialize client_ids:, date:
      @client_ids = client_ids
      @date = date
    end

    def perform
      GrdaWarehouse::EnrollmentChangeHistory.create_for_clients_on_date! client_ids: @client_ids, date: @date
    end

    def enqueue(job, queue: :low_priority)
    end

    def max_attempts
      1
    end

  end
end