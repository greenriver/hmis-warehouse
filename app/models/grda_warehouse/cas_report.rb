###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  # gets dumped into by CAS
  class CasReport < GrdaWarehouseBase
    def readonly?
      true
    end
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', inverse_of: :cas_reports, optional: true

    scope :started_between, ->(start_date:, end_date:) do
      where(match_started_at: (start_date..end_date))
    end

    scope :open_between, ->(start_date:, end_date:) do
      at = arel_table
      # Excellent discussion of why this works:
      # http://stackoverflow.com/questions/325933/determine-whether-two-date-ranges-overlap
      d_1_start = start_date
      d_1_end = end_date
      d_2_start = at[:match_started_at]
      d_2_end = at[:updated_at]
      # Currently does not count as an overlap if one starts on the end of the other
      where(d_2_end.gteq(d_1_start).or(d_2_end.eq(nil)).and(d_2_start.lteq(d_1_end)))
    end

    scope :match_closed, -> do
      where(active_match: false)
    end

    scope :match_failed, -> do
      where.not(terminal_status: ['In Progress', 'Success', 'New'])
    end

    scope :canceled, -> do
      where.not(administrative_cancel_reason: nil)
    end

    scope :declined, -> do
      where.not(decline_reason: nil)
    end

    scope :canceled_between, ->(start_date:, end_date:) do
      canceled.where(updated_at: (start_date..end_date))
    end

    scope :on_route, ->(route_name) do
      where(match_route: route_name)
    end

    scope :ineligible_in_warehouse, -> do
      where(ineligible_in_warehouse: true)
    end

    def self.match_routes
      distinct.order(match_route: :asc).pluck(:match_route)
    end

    def self.decline_reason_attributes
      {
        client_id: 'Client',
        match_id: 'Match',
        decline_reason: 'Decline Reason',
        match_started_at: 'Match Started',
      }
    end

    def self.cancelation_reason_attributes
      {
        client_id: 'Client',
        match_id: 'Match',
        administrative_cancel_reason: 'Decline Reason',
        match_started_at: 'Match Started',
      }
    end
  end
end
