###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# ### HIPPA Risk Assessment
# Risk: Describes a patient and contains PHI
# Control: PHI attributes documented
module Health::Claims
  class TopProviders < Base
    self.table_name = :claims_top_providers

    phi_patient :medicaid_id
    phi_attr :provider_name, Phi::SmallPopulation

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