###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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
    attr_accessor :client_ids # used to speed up calculations when paginated

    def initialize(filter)
      @filter = filter
    end

    def self.name
      Translation.translate('Client Activity Report')
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
      options = {
        include_reporting_period: false,
        include_comparison_period: false,
        include_require_service_during_range: false,
      }
      [
        build_general_control_section(options: options),
        build_days_since_contact_control_section,
        build_coc_control_section,
      ]
    end

    def total_client_count
      @total_client_count ||= clients.count
    end

    def clients
      GrdaWarehouse::Hud::Client.where(id: report_scope.select(:client_id)).
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
        most_recent_ce_assessment(client)&.dig(:assessment_date),
        max_entry_date(client),
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

    def max_entry_date(client)
      activities[:entries][client.id]
    end

    def activities
      @activities ||= {
        cls: max_current_living_situation_by_client_id,
        bed_nights: max_bed_night_by_client_id,
        assessments: max_assessment_by_client_id,
        entries: max_entries_by_client_id,
      }
    end

    def client_scope
      scope = GrdaWarehouse::Hud::Client.
        joins(service_history_entries: :project).
        merge(GrdaWarehouse::ServiceHistoryEnrollment.where(client_id: report_scope.select(:client_id))).
        merge(GrdaWarehouse::Hud::Project.viewable_by(filter.user))
      scope = scope.where(id: client_ids) if client_ids.present?
      scope
    end

    def max_current_living_situation_by_client_id
      client_scope.
        joins(:source_current_living_situations).
        group(c_t[:id]).
        maximum(cls_t[:InformationDate])
    end

    def max_bed_night_by_client_id
      client_scope.
        joins(:source_services).
        merge(GrdaWarehouse::Hud::Service.bed_night).
        group(c_t[:id]).
        maximum(s_t[:DateProvided])
    end

    def max_assessment_by_client_id
      u_t = GrdaWarehouse::Hud::User.arel_table
      client_scope.
        joins(source_assessments: :user).
        pluck(c_t[:id], u_t[:UserFirstName], u_t[:UserLastName], as_t[:AssessmentDate]).
        uniq.
        map { |id, first_name, last_name, date| [id, "#{last_name}, #{first_name}", date] }.
        group_by(&:shift).
        map do |id, values|
          latest_assessment = values.max_by(&:last)
          { id => {
            assessor: latest_assessment.first,
            assessment_date: latest_assessment.last,
          } }
        end.
        reduce :merge
    end

    private def max_entries_by_client_id
      scope = report_scope
      scope = scope.where(client_id: client_ids) if client_ids.present?
      scope.
        order(entry_date: :asc).
        pluck(:client_id, :entry_date).
        to_h # Keeps the last instance for each client_id
    end

    def report_scope
      scope = filter.apply(report_scope_base, report_scope_base, include_date_range: false)
      # Apply a single date filter
      scope.ongoing(on_date: filter.on)
    end

    def report_scope_base
      GrdaWarehouse::ServiceHistoryEnrollment.entry
    end
  end
end
