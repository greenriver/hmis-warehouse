###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::WarehouseReports::DocumentExports
  class ClientLookupExport < ::GrdaWarehouse::DocumentExport
    REPORT_URL = 'warehouse_reports/client_lookups'

    def authorized?
      user.can_view_any_reports? &&
        report_definition_source.viewable_by(user).exists? &&
        filter.any_effective_project_ids? &&
        report.any_authorized_projects?
    end

    def download_title
      'Client Personal ID Lookup'
    end

    def perform
      with_status_progression do
        self.filename = "client-lookups-#{Date.current.to_fs(:db)}.xlsx"
        self.file_data = report.to_xlsx(report.rows)
        self.mime_type = EXCEL_MIME_TYPE
      end
    end

    def report
      @report ||= ::WarehouseReports::ClientLookups::Report.new(
        filter: filter,
        user: user,
        map_enrollments: map_enrollments,
      )
    end

    # Overrides the base, which builds a bare `Filters::FilterBase`. This report has no
    # CoC picker, and `Filters::ClientLookup` exists to keep CoC codes from contributing
    # to project scoping (see its comment); using the base filter here would silently
    # widen the project scope. `enforce_one_year_range: false` matches the form, which
    # allows multi-year ranges.
    def filter
      @filter ||= begin
        f = ::Filters::ClientLookup.new(user_id: user.id, enforce_one_year_range: false)
        f.update(report_params.slice(*known_filter_keys(f)))
        f
      end
    end

    # `known_params` mixes plain symbols with a trailing hash of array-valued params
    # (`project_ids: []`, ...). Flatten it to the string keys the parsed query string
    # uses, so slicing here permits exactly what the controller's `permit` does.
    private def known_filter_keys(filter)
      filter.known_params.flat_map { |param| param.is_a?(Hash) ? param.keys : param }.map(&:to_s)
    end

    # `map_enrollments` is deliberately not part of `filter.known_params`, so it has to
    # be carried separately out of the submitted query string.
    protected def map_enrollments
      ActiveModel::Type::Boolean.new.cast(report_params['map_enrollments'])
    end

    # The filter form serializes its inputs under `report[...]`, matching what
    # `ClientLookupsController` reads from the request.
    protected def report_params
      params['report'].presence || {}
    end

    protected def report_definition_source
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: REPORT_URL)
    end
  end
end
