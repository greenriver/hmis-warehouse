###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module InactiveClientReport
  class Report
    include Filter::ControlSections
    include Filter::FilterScopes
    include ActionView::Helpers::NumberHelper
    include ArelHelper

    attr_accessor :filter

    def initialize(filter)
      @filter = filter
    end

    def self.url
      'inactive_client_report/warehouse_reports/reports'
    end

    def include_comparison?
      false
    end

    def report_path_array
      [
        :inactive_client_report,
        :warehouse_reports,
        :reports,
      ]
    end

    def self.viewable_by(user)
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: url).
        viewable_by(user).exists?
    end

    def multiple_project_types?
      true
    end

    def filter_path_array
      [:filters] + report_path_array
    end

    protected def build_control_sections
      [
        build_general_control_section,
        build_coc_control_section,
      ]
    end

    def total_client_count
      @total_client_count ||= clients.count
    end

    def clients
      GrdaWarehouse::Hud::Client.where(id: enrollments.pluck(:client_id)).
        preload(
          :processed_service_history,
          service_history_entry_ongoing: :project,
        )
    end

    def days_since_most_recent_contact(client)
      date = most_recent_contact(client)
      return unless date.present?

      (Date.current - date).to_i
    end

    def most_recent_contact(client)
      [
        most_recent_cls(client),
        most_recent_bed_night(client),
        most_recent_ce_assessment(client),
      ].compact.max
    end

    def most_recent_cls(client)
      activities[:cls][client.id]
    end

    def most_recent_bed_night(client)
      activities[:bed_nights][client.id]
    end

    def most_recent_ce_assessment(client)
      activities[:assessments][client.id]
    end

    def activities
      @activities ||= {
        cls: max_current_living_situation_by_client_id,
        bed_nights: max_bed_night_by_client_id,
        assessments: max_assessment_by_client_id,
      }
    end

    def max_current_living_situation_by_client_id
      clients.joins(:source_current_living_situations).
        group(:id).
        maximum(cls_t[:InformationDate])
    end

    def max_bed_night_by_client_id
      GrdaWarehouse::Hud::Client.
        joins(:source_services).
        merge(GrdaWarehouse::Hud::Service.bed_night).
        group(:id).
        maximum(s_t[:DateProvided])
    end

    def max_assessment_by_client_id
      GrdaWarehouse::Hud::Client.
        joins(:source_assessments).
        group(:id).
        maximum(as_t[:AssessmentDate])
    end

    def enrollments
      filter.apply(report_scope_base)
    end

    def report_scope_base
      GrdaWarehouse::ServiceHistoryEnrollment.entry
    end
  end
end
