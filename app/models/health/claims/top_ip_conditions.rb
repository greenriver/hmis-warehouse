module Health::Claims
  class TopIpConditions < Base
    self.table_name = :claims_top_ip_conditions

    def column_headers 
      {
        medicaid_id: "ID_Medicaid",
        rank: "Rank",
        description: "Description",
        indiv_pct: "Indiv_pct",
        sdh_pct: "SDH_pct",
      }
    end

  end
end