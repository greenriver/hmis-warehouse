module Health::ClaimsImporter
  class EdNyuSeverity < Base
    self.table_name = :claims_ed_nyu_severity

    def column_headers 
      {
        medicaid_id: "ID_Medicaid",
        category: "Category",
        indiv_pct: "Indiv_pct",
        sdh_pct: "SDH_pct",
      }
    end

  end
end