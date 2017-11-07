module Health::Claims
  class TopProviders < Base
    self.table_name = :claims_top_providers

    def column_headers 
      {
        medicaid_id: "ID_Medicaid",
        rank: "Rank",
        provider_name: "serv_name_dsp",
        indiv_pct: "Implementation pct",
        sdh_pct: "Baseline pct",
      }
    end

  end
end