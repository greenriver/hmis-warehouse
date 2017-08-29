module GrdaWarehouse
  # gets dumped into by CAS
  class CasReport < GrdaWarehouseBase
    def readonly?
      true
    end
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', inverse_of: :cas_reports

    scope :started_between, -> (start_date:, end_date:) do
      where(match_started_at: (start_date..end_date))
    end

    scope :canceled, -> do
      where.not(administrative_cancel_reason: nil)
    end

    scope :canceled_between, -> (start_date:, end_date:) do
      canceled.where(updated_at: (start_date..end_date))
    end

    def self.reason_attributes
      {
        client_id: 'Client',
        match_id: 'Match',
        decline_reason: 'Decline Reason',
        match_started_at: 'Match Started',
      }
    end

  end
end