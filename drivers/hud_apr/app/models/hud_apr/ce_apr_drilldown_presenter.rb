# frozen_string_literal: true

module HudApr
  class CeAprDrilldownPresenter < DrilldownPresenter
    def extra_fields
      {
        'Question 5' => age_fields + parenting_fields + veteran_fields + homeless_fields,
        'Question 6' => pii_fields + universal_data_fields + financial_fields + housing_fields + project_fields + timeliness_fields + inactive_records_fields,
        'Question 7' => household_fields + parenting_fields + project_fields,
        'Question 8' => household_fields + parenting_fields + project_fields,
        'Question 9' => household_fields + ce_fields + project_fields,
        'Question 10' => ce_fields + project_fields,
      }
    end
  end
end
