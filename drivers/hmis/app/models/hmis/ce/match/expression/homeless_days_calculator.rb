# frozen_string_literal: true

module Hmis::Ce::Match::Expression
  # Calculates the total number of days a client has been homeless.
  # Excludes days when the client was housed (housed status takes precedence over homeless).
  class HomelessDaysCalculator
    def initialize(current_date)
      @current_date = current_date
    end

    def call(clients)
      client_ids = clients.pluck(:id)
      housed_dates_by_client = fetch_housed_dates(client_ids)
      homeless_dates_by_client = fetch_homeless_dates(client_ids)

      calculate_homeless_days(client_ids, housed_dates_by_client, homeless_dates_by_client)
    end

    private

    def fetch_housed_dates(client_ids)
      # First identify any days the client was housed, as these will be excluded from the count.
      # A client can have both homeless and housed service history records on the same day,
      # with "housed" taking precedence.
      housed_dates = GrdaWarehouse::ServiceHistoryService.non_homeless.
        where(client_id: client_ids).
        distinct.
        pluck(:client_id, :date)

      housed_dates.group_by(&:first).transform_values { |dates| dates.map(&:last) }
    end

    def fetch_homeless_dates(client_ids)
      # Gather all unique days where the client had a homeless status service recorded.
      homeless_dates = GrdaWarehouse::ServiceHistoryService.where(client_id: client_ids).
        homeless.
        where(arel.shs_t[:date].lteq(@current_date)).
        pluck(:client_id, :date)

      homeless_dates.group_by(&:first).transform_values { |dates| dates.map(&:last) }
    end

    def calculate_homeless_days(client_ids, housed_dates_by_client, homeless_dates_by_client)
      # For each client, count the number of unique homeless days,
      # ensuring any days they were housed are not included in the final count.
      client_ids.index_with do |client_id|
        homeless_for_client = homeless_dates_by_client[client_id]
        next nil unless homeless_for_client

        housed_for_client = housed_dates_by_client[client_id] || []
        (homeless_for_client.uniq - housed_for_client.uniq).count
      end
    end

    def arel
      Hmis::ArelHelper
    end
  end
end
