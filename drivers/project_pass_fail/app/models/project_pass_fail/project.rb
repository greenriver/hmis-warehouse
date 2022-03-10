###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ProjectPassFail
  class Project < GrdaWarehouseBase
    self.table_name = :project_pass_fails_projects
    belongs_to :project_pass_fail, inverse_of: :projects
    belongs_to :apr, class_name: 'HudReports::ReportInstance', optional: true
    belongs_to :project, class_name: 'GrdaWarehouse::Hud::Project', optional: true
    has_many :clients, inverse_of: :project, dependent: :destroy

    # Data quality acceptable error rates
    def universal_data_element_threshold
      project_pass_fail.universal_data_element_threshold
    end

    # Acceptable utilization rates
    def utilization_range
      project_pass_fail.utilization_range
    end

    # Days allowed for entering entry assessments
    def timeliness_threshold
      project_pass_fail.timeliness_threshold
    end

    def utilization_rate_as_percent
      (utilization_rate * 100).round(2)
    end

    def unit_utilization_rate_as_percent
      (unit_utilization_rate * 100).round(2)
    end

    def within_utilization_threshold?
      utilization_rate.in?(utilization_range)
    end

    def within_unit_utilization_threshold?
      unit_utilization_rate.in?(utilization_range)
    end

    def within_universal_data_element_threshold?
      universal_data_element_rates.values.compact.max <= universal_data_element_threshold
    end

    def within_timeliness_threshold?
      average_days_to_enter_entry_date <= timeliness_threshold
    end

    def universal_data_element_rates
      ude = {
        'Name' => name_error_rate,
        'SSN' => ssn_error_rate,
        'DOB' => dob_error_rate,
        'Race' => race_error_rate,
        'Ethnicity' => ethnicity_error_rate,
        'Gender' => gender_error_rate,
        'Veteran' => veteran_status_error_rate,
        'Entry Date' => start_date_error_rate,
        'Relationship to HoH' => relationship_to_hoh_error_rate,
        'Location' => location_error_rate,
        'Disabling Condition' => disabling_condition_error_rate,
      }
      ude['Income at Entry'] = income_at_entry_error_rate if GrdaWarehouse::Config.get(:pf_show_income)
      ude
    end

    def calculate_utilization_rate
      self.utilization_rate = if available_beds.positive? && clients.exists?
        clients.sum(:days_served).to_f / project_pass_fail.filter.range.count / available_beds
      else
        0
      end
      self.utilization_count = clients.count

      self.unit_utilization_rate = if available_units.positive? && clients.exists?
        clients.heads_of_household.sum(:days_served).to_f / project_pass_fail.filter.range.count / available_units
      else
        0
      end
      self.unit_utilization_count = clients.heads_of_household.count
    end

    private def destination_client_service_counts
      @destination_client_service_counts ||= ::GrdaWarehouse::ServiceHistoryService.where(
        date: project_pass_fail.filter.range,
      ).
        joins(:service_history_enrollment).
        merge(
          GrdaWarehouse::ServiceHistoryEnrollment.entry.
            where(
              project_id: project.ProjectID,
              data_source_id: project.data_source_id,
            ),
        ).
        group(:client_id).distinct.count(:date)
    end

    def service_counts_for(destination_client_id)
      destination_client_service_counts[destination_client_id]
    end

    def calculate_universal_data_element_rates
      self.name_error_rate = apr.answer(question: 'Q6a', cell: 'F2').summary.to_f
      self.ssn_error_rate = apr.answer(question: 'Q6a', cell: 'F3').summary.to_f
      self.dob_error_rate = apr.answer(question: 'Q6a', cell: 'F4').summary.to_f
      self.race_error_rate = apr.answer(question: 'Q6a', cell: 'F5').summary.to_f
      self.ethnicity_error_rate = apr.answer(question: 'Q6a', cell: 'F6').summary.to_f
      self.gender_error_rate = apr.answer(question: 'Q6a', cell: 'F7').summary.to_f
      self.veteran_status_error_rate = apr.answer(question: 'Q6b', cell: 'C2').summary.to_f
      self.start_date_error_rate = apr.answer(question: 'Q6b', cell: 'C3').summary.to_f
      self.relationship_to_hoh_error_rate = apr.answer(question: 'Q6b', cell: 'C4').summary.to_f
      self.location_error_rate = apr.answer(question: 'Q6b', cell: 'C5').summary.to_f
      self.disabling_condition_error_rate = apr.answer(question: 'Q6b', cell: 'C6').summary.to_f
      self.income_at_entry_error_rate = apr.answer(question: 'Q6c', cell: 'C3').summary.to_f

      self.name_error_count = apr.answer(question: 'Q6a', cell: 'E2').summary.to_f
      self.ssn_error_count = apr.answer(question: 'Q6a', cell: 'E3').summary.to_f
      self.dob_error_count = apr.answer(question: 'Q6a', cell: 'E4').summary.to_f
      self.race_error_count = apr.answer(question: 'Q6a', cell: 'E5').summary.to_f
      self.ethnicity_error_count = apr.answer(question: 'Q6a', cell: 'E6').summary.to_f
      self.gender_error_count = apr.answer(question: 'Q6a', cell: 'E7').summary.to_f
      self.veteran_status_error_count = apr.answer(question: 'Q6b', cell: 'B2').summary.to_f
      self.start_date_error_count = apr.answer(question: 'Q6b', cell: 'B3').summary.to_f
      self.relationship_to_hoh_error_count = apr.answer(question: 'Q6b', cell: 'B4').summary.to_f
      self.location_error_count = apr.answer(question: 'Q6b', cell: 'B5').summary.to_f
      self.disabling_condition_error_count = apr.answer(question: 'Q6b', cell: 'B6').summary.to_f
      self.income_at_entry_error_count = apr.answer(question: 'Q6c', cell: 'B3').summary.to_f
    end

    def calculate_timeliness
      self.average_days_to_enter_entry_date = if clients.exists?
        clients.sum(:days_to_enter_entry_date) / clients.count.to_f
      else
        0
      end
    end
  end
end
