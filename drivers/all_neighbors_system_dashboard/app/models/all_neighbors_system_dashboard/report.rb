###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AllNeighborsSystemDashboard
  class Report < SimpleReports::ReportInstance
    include Filter::ControlSections
    include Filter::FilterScopes
    include Reporting::Status

    after_initialize :filter

    scope :visible_to, ->(user) do
      return all if user.can_view_all_reports?
      return where(user_id: user.id) if user.can_view_assigned_reports?

      none
    end

    scope :ordered, -> do
      order(updated_at: :desc)
    end

    def title
      _('All Neighbors System Dashboard')
    end

    def report_path_array
      [
        :all_neighbors_system_dashboard,
        :warehouse_reports,
        :all_neighbors_system_dashboards,
      ]
    end

    def default_project_type_codes
      GrdaWarehouse::Hud::Project::PERFORMANCE_REPORTING.keys
    end

    def project_type_ids
      filter.project_type_ids
    end

    def multiple_project_types?
      true
    end

    def filter
      @filter ||= begin
        f = ::Filters::FilterBase.new(
          user_id: user_id,
          enforce_one_year_range: false,
        )
        f.update(options.with_indifferent_access.merge(enforce_one_year_range: false)) if options.present?
        f
      end
    end

    private def build_control_sections
      []
    end
  end
end
