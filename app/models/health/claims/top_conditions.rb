###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Describes a patient and contains PHI
# Control: PHI attributes documented
module Health::Claims
  class TopConditions < Base
    self.table_name = :claims_top_conditions

    phi_patient :medicaid_id
    phi_attr :description, Phi::SmallPopulation, "Description of conditions"

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
