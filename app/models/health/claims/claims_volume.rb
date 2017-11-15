module Health::Claims
  class ClaimsVolume < Base
    self.table_name = :claims_claim_volume_location_month
    
    def column_headers 
      {
        medicaid_id: "ID_Medicaid",
        year: "Year",
        month: "Month",
        year_month: 'YYYYMM',
        study_period: 'StudyPeriod',
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