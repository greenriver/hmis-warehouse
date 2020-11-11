###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module ProjectPassFail
  class Project < GrdaWarehouseBase
    self.table_name = :project_pass_fails_projects
    belongs_to :project_pass_fail, inverse_of: :projects
    belongs_to :apr, class_name: 'HudReports::ReportInstance'
    has_many :clients, inverse_of: :project, dependent: :destroy

    def calculate_utilization_rate
      self.utilization_rate = if available_beds.positive? && clients.exist?
        clients.count.to_f / available_beds
      else
        0
      end
    end

    def calculate_universal_data_element_rates
      self.name_error_rate = apr.answer(question: 'Q6a', cell: 'F2').summary
      self.ssn_error_rate = apr.answer(question: 'Q6a', cell: 'F3').summary
      self.dob_error_rate = apr.answer(question: 'Q6a', cell: 'F4').summary
      self.race_error_rate = apr.answer(question: 'Q6a', cell: 'F5').summary
      self.ethnicity_error_rate = apr.answer(question: 'Q6a', cell: 'F6').summary
      self.gender_error_rate = apr.answer(question: 'Q6a', cell: 'F7').summary
      self.veteran_status_error_rate = apr.answer(question: 'Q6b', cell: 'C2').summary
      self.start_date_error_rate = apr.answer(question: 'Q6b', cell: 'C3').summary
      self.relationship_to_hoh_error_rate = apr.answer(question: 'Q6b', cell: 'C4').summary
      self.location_error_rate = apr.answer(question: 'Q6b', cell: 'C5').summary
      self.disabling_condition_error_rate = apr.answer(question: 'Q6b', cell: 'C6').summary

      self.name_error_count = apr.answer(question: 'Q6a', cell: 'E2').summary
      self.ssn_error_count = apr.answer(question: 'Q6a', cell: 'E3').summary
      self.dob_error_count = apr.answer(question: 'Q6a', cell: 'E4').summary
      self.race_error_count = apr.answer(question: 'Q6a', cell: 'E5').summary
      self.ethnicity_error_count = apr.answer(question: 'Q6a', cell: 'E6').summary
      self.gender_error_count = apr.answer(question: 'Q6a', cell: 'E7').summary
      self.veteran_status_error_count = apr.answer(question: 'Q6b', cell: 'B2').summary
      self.start_date_error_count = apr.answer(question: 'Q6b', cell: 'B3').summary
      self.relationship_to_hoh_error_count = apr.answer(question: 'Q6b', cell: 'B4').summary
      self.location_error_count = apr.answer(question: 'Q6b', cell: 'B5').summary
      self.disabling_condition_error_count = apr.answer(question: 'Q6b', cell: 'B6').summary
    end
  end
end
