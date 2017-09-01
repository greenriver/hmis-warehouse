module Health::ClaimsImporter
  class ClaimsVolume < Base
    self.table_name = :claims_claim_volume_location_month
    
    def column_headers 
      {
        medicaid_id: "ID_Medicaid",
        year: "Year",
        month: "Month",
        ip: "IP",
        emerg: "Emerg",
        respite: "Respite",
        op: "OP",
        rx: "Rx",
        other: "Other",
        total: "Total",
      }
    end

  end
end