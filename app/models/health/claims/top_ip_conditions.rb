module Health::Claims
  class TopIpConditions < Base
    self.table_name = :claims_top_ip_conditions

    def column_headers 
      {
        medicaid_id: "ID_Medicaid",
        rank: "Rank",
        description: "Description",
        indiv_pct: "Implementation pct",
        sdh_pct: "Baseline pct",
      }
    end

  end
end