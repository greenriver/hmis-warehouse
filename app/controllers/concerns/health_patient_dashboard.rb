###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
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
  end
end
