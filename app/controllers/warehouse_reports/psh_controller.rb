###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class PshController < RrhController
    include WarehouseReportAuthorization
    include ArelHelper
    include PjaxModalController

    private def set_report
      @report = WarehouseReport::PshReport.new(
        project_ids: @filter.project_ids,
        start_date: @filter.start_date,
        end_date: @filter.end_date,
        subpopulation: @filter.subpopulation,
        household_type: @filter.household_type,
        race: @filter.race,
        ethnicity: @filter.ethnicity,
        gender: @filter.gender,
        veteran_status: @filter.veteran_status,
      )
    end

    private def available_projects
      @available_projects ||= project_source.with_project_type([3, 9, 10]).
        joins(:organization).
        pluck(o_t[:OrganizationName].to_sql, :ProjectName, :id).
        map do |org_name, project_name, id|
          ["#{project_name} >> #{org_name}", id]
        end
    end

    def describe_computations
      path = 'app/views/warehouse_reports/psh/README.md'
      description = File.read(path)
      markdown = Redcarpet::Markdown.new(::TranslatedHtml)
      markdown.render(description)
    end
    helper_method :describe_computations
  end
end
