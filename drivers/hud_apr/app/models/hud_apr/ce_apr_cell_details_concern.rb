###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::CeAprCellDetailsConcern
  extend ActiveSupport::Concern

  included do
    def self.extra_fields
      {
        'Question 5' => age_fields + parenting_fields + veteran_fields + homeless_fields,
        'Question 6' => pii_fields + universal_data_fields + financial_fields + housing_fields + project_fields + timeliness_fields + inactive_records_fields,
        'Question 7' => household_fields + parenting_fields + project_fields,
        'Question 8' => household_fields + parenting_fields + project_fields,
        'Question 9' => household_fields + ce_fields + project_fields,
        'Question 10' => ce_fields + project_fields,
      }
    end

    def self.ce_fields
      [
        :ce_assessment_date,
        :ce_assessment_type,
        :ce_assessment_prioritization_status,
        :ce_event_date,
        :ce_event_event,
        :ce_event_problem_sol_div_rr_result,
        :ce_event_referral_case_manage_after,
        :ce_event_referral_result,
      ].freeze
    end
  end
end
