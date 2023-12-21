###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ZipCodeReport
  class Report
    include Filter::ControlSections
    include Filter::FilterScopes
    include ActionView::Helpers::NumberHelper
    include ArelHelper
    include ApplicationHelper

    attr_accessor :filter

    def initialize(filter)
      @filter = filter
    end

    def self.url
      'zip_code_report/warehouse_reports/reports'
    end

    def include_comparison?
      false
    end

    def report_path_array
      [
        :zip_code_report,
        :warehouse_reports,
        :reports,
      ]
    end

    def self.viewable_by(user)
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: url).
        viewable_by(user).exists?
    end

    def filter_path_array
      [:filters] + report_path_array
    end

    def zip_codes
      @zip_codes ||= enrollments.distinct.
        joins(project: :project_cocs).
        select('ProjectCoC.Zip')
    end

    def total_client_count
      zip_code_data.collect { |_, v| v[:client].count }.sum
    end

    def zip_code_data
      @zip_code_data ||= Rails.cache.fetch([self.class.name, @filter.attributes, __method__], expires_in: 5.minutes) do
        {}.tap do |data|
          enrollments.distinct.
            joins(project: :project_cocs).
            pluck(:client_id, 'ProjectCoC.Zip').
            each do |client_id, zip|
              data[zip] ||= {}
              data[zip][:client] ||= Set.new
              data[zip][:household] ||= Set.new

              data[zip][:client] << client_id
              data[zip][:household] << client_id if hoh_client_ids.include?(client_id)
            end
        end
      end
    end

    def clients_count(zip)
      return zip_code_data[zip][:client]&.count
    end

    def households_count(zip)
      return zip_code_data[zip][:household]&.count
    end

    def enrollments
      @enrollments ||= filter.apply(report_scope_base, report_scope_base)
    end

    def report_scope_base
      GrdaWarehouse::ServiceHistoryEnrollment.entry
    end

    private def hoh_scope
      enrollments.where(she_t[:head_of_household].eq(true))
    end

    private def hoh_client_ids
      @hoh_client_ids ||= hoh_scope.pluck(:client_id)
    end

    def multiple_project_types?
      true
    end
  end
end
