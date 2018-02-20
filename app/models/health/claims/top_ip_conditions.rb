module Health::Claims
  class TopIpConditions < Base
    self.table_name = :claims_top_ip_conditions

    def column_headers 
      {
        medicaid_id: "ID_Medicaid",
        rank: "Rank",
        description: "Description",
        sdh_pct: "baseline pct",
        indiv_pct: "implement pct",
        baseline_paid: 'baseline paid',
        implementation_paid: 'implement paid',
      }
    end

  end
end