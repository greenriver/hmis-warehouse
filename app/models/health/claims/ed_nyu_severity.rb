###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# ### HIPPA Risk Assessment
# Risk: Describes a patient and contains PHI
# Control: PHI attributes documented
module Health::Claims
  class EdNyuSeverity < Base
    self.table_name = :claims_ed_nyu_severity

    phi_patient :medicaid_id

    def column_headers
      {
        medicaid_id: "ID_MEDICAID",
        category: "Category",
        sdh_pct: "Baseline_pct",
        indiv_pct: "Implement_pct",
        baseline_visits: 'Baseline_visits',
        implementation_visits: 'Implement_visits',
      }
    end

    def clean_rows(dirty)
      dirty.map do |row|
        row.map do |value|
          if value == "#DIV/0!"
            nil
          else
            value
          end
        end
      end
    end

  end
end