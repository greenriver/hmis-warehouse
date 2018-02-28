module Health::Claims
  class TopProviders < Base
    self.table_name = :claims_top_providers

    def column_headers 
      {
        medicaid_id: "ID_MEDICAID",
        rank: "Rank",
        provider_name: "SERV_NAME_DSP",
        sdh_pct: "Baseline_pct",
        indiv_pct: "Implement_pct",
        baseline_paid: 'Baseline_paid',
        implementation_paid: 'Implement_paid',
      }
    end

  end
end