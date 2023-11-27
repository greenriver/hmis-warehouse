###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthPatientDashboard
  extend ActiveSupport::Concern

  included do
    def sort_options
      sort_options = [
        {
          column: 'name',
          direction: :asc,
          title: 'Name (last, first) A-Z',
        },
        {
          column: 'name',
          direction: :desc,
          title: 'Name (last, first) Z-A',
        },
      ]

      Rails.application.config.patient_dashboards.map do |dashboard|
        dashboard_sort_options = dashboard[:calculator].constantize.dashboard_sort_options
        sort_options << dashboard_sort_options if dashboard_sort_options.present?
      end

      sort_options
    end
    helper_method :sort_options

    def calculate_dashboards(medicaid_ids)
      Rails.application.config.patient_dashboards.map do |dashboard|
        [
          dashboard[:title],
          dashboard[:calculator].constantize.new(medicaid_ids).to_map,
        ]
      end.to_h
    end

    def determine_sort_order(medicaid_ids, column, direction)
      Rails.application.config.patient_dashboards.map do |dashboard|
        sort_order = dashboard[:calculator].constantize.new(medicaid_ids).sort_order(column, direction)
        return sort_order if sort_order.present?
      end
      raise 'Unknown sort column'
    end

    # @param patients Initial patients scope
    # @param Hash<String>|nil Filters
    # @return patient_scope, search_scope, active_filter
    def apply_filter(patients, filter)
      search = search_setup(search: patients, scope: :full_text_search)
      patients = search.distinct if @search_string.present?
      active_filter = false
      return search, patients, active_filter unless filter.present?

      # Status Filter
      active_filter = true if filter[:population] != 'all'
      case filter[:population]
      when 'not_engaged'
        patients = patients.not_engaged
      when 'needs_f2f'
        patients = patients.needs_f2f
      when 'needs_qa'
        patients = patients.needs_qa
      when 'needs_intake'
        patients = patients.needs_intake
      when 'needs_renewal'
        patients = patients.needs_renewal
      end

      # Needs filter
      current_careplans = HealthPctp::Careplan.
        where(patient_id: patients.select(:id)).
        order(created_at: :asc).
        index_by(&:patient_id)

      patients_with_needs = []
      needs_filter = false
      if filter[:ncm_review].present?
        needs_filter = true
        patients_with_needs += current_careplans.select { |_, v| v.reviewed_by_rn_on.blank? }.values.map(&:patient_id)
      end
      if filter[:manager_review].present?
        needs_filter = true
        patients_with_needs += current_careplans.select { |_, v| v.reviewed_by_ccm_on.blank? && v.reviewed_by_rn_on.present? }.values.map(&:patient_id)
      end
      if filter[:sent_to_pcp].present?
        needs_filter = true
        patients_with_needs += current_careplans.select { |_, v| v.sent_to_pcp_on.blank? && v.reviewed_by_ccm_on.present? && v.reviewed_by_rn_on.present? }.values.map(&:patient_id)
      end

      if needs_filter
        active_filter = true
        patients = patients.where(id: patients_with_needs)
      end

      # Team Member filter
      if filter[:user].present?
        active_filter = true
        user_id = if filter[:user] == 'unassigned'
          nil
        else
          filter[:user].to_i
        end

        patients = patients.where(care_coordinator_id: user_id)
      end

      if filter[:nurse_care_manager_id].present?
        active_filter = true
        nurse_care_manager_id = if filter[:nurse_care_manager_id] == 'unassigned'
          nil
        else
          filter[:nurse_care_manager_id].to_i
        end

        patients = patients.where(nurse_care_manager_id: nurse_care_manager_id)
      end

      return search, patients, active_filter
    end
  end
end
