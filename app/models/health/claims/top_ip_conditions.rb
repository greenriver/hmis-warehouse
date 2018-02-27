module Health::Claims
  class TopIpConditions < Base
    self.table_name = :claims_top_ip_conditions

    def column_headers 
      {
        medicaid_id: "ID_MEDICAID",
        rank: "Rank",
        description: "Description",
        sdh_pct: "Baseline_pct",
        indiv_pct: "Implement_pct",
        baseline_paid: 'Baseline_paid',
        implementation_paid: 'Implement_paid',
      }
    end

  end
end