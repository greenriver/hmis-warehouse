###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Describes a patient and contains PHI
# Control: PHI attributes documented
module Health::Claims
  class Roster < Base
    self.table_name = :claims_roster

    phi_patient :medicaid_id
    phi_attr :last_name, Phi::Name
    phi_attr :first_name, Phi::Name
    # phi_attr :gender
    phi_attr :dob, Phi::Date
    # phi_attr :race
    # phi_attr :primary_language
    # phi_attr :disability_flag
    # phi_attr :norm_risk_scores
    # phi_attr :mbr_months
    # phi_attr :total_ty
    # phi_attr :ed_visits
    # phi_attr :acute_ip_admits
    # phi_attr :average_days_to_readmit
    phi_attr :pcp, Phi::SmallPopulation
    phi_attr :epic_team, Phi::SmallPopulation
    # phi_attr :member_months_baseline
    # phi_attr :member_months_implementation
    # phi_attr :cost_rank_ty
    # phi_attr :average_ed_visits_baseline
    # phi_attr#  :average_ed_visits_implementation
    # phi_attr :average_ip_admits_baseline
    # phi_attr :average_ip_admits_implementation
    # phi_attr :average_days_to_readmit_baseline
    # phi_attr :average_days_to_implementation
    phi_attr :case_manager, Phi::SmallPopulation
    # phi_attr :housing_status
    # phi_attr :baseline_admits
    # phi_attr :implementation_admits

    def column_headers
      {
        medicaid_id: "id_medicaid",
        member_months_baseline: 'Baseline_mem_mos',
        member_months_implementation: 'Implement_mem_mos',
        baseline_admits: 'Baseline_admits',
        implementation_admits: 'Implement_admits',
        average_days_to_readmit_baseline: "Baseline_avg_days_readmit",
        average_days_to_implementation: "Implement_avg_days_readmit",
      }
    end

    def clean_rows(dirty)
      dirty.map do |row|
        row.map do |value|
          case value
          when 'Y'
            true
          when 'N'
            false
          when 'N/A', '#N/A', '#DIV/0!'
            nil
          else
            value
          end
        end
      end
    end

  end
end
