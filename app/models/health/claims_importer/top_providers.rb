module Health::ClaimsImporter
  class TopProviders < Base
    self.table_name = :claims_top_providers

    def column_headers 
      {
        medicaid_id: "ID_Medicaid",
        rank: "Rank",
        provider_name: "Provider name",
        indiv_pct: "Indiv_pct",
        sdh_pct: "SDH_pct",
      }
    end

  end
end