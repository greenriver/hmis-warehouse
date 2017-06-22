module GrdaWarehouse
  # gets dumped into by CAS
  class CasReport < GrdaWarehouseBase
    def readonly?
      true
    end
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', inverse_of: :cas_reports

    def self.reason_attributes
      {
        client_id: 'Client',
        match_id: 'Match',
        decline_reason: 'Decline Reason',
        created_at: 'Match Created',
      }
    end

  end
end