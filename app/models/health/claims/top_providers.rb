module Health::Claims
  class TopProviders < Base
    self.table_name = :claims_top_providers

    def column_headers 
      {
        medicaid_id: "ID_Medicaid",
        rank: "Rank",
        provider_name: "serv_name_dsp",
        sdh_pct: "Baseline pct",
        indiv_pct: "implement pct",
        baseline_paid: 'Baseline paid',
        implementation_paid: 'implement paid',
      }
    end

  end
end