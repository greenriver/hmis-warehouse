###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# The export is generated elsewhere. This just orchestrates getting the excel
# spreadsheet and "reshaping" to CSVs

module HmisExternalApis::AcHmis::Exporters
  class ProjectsCrossWalkFetcher
    def run!
      # For reference:
      #   - app/views/warehouse_reports/hmis_cross_walks/index.xlsx.axlsx
      #   - app/controllers/warehouse_reports/hmis_cross_walks_controller.rb

      filter = ::Filters::FilterBase.new(user_id: User.system_user.id, enforce_one_year_range: false)
      filter.update(
        start: 10.years.ago.to_date,
        end: Date.current,
        data_source_ids: [HmisExternalApis::AcHmis.data_source.id],
      )

      projects = GrdaWarehouse::Hud::Project.active_during(filter.range).distinct
      projects = projects.where(id: filter.effective_project_ids) if filter.any_effective_project_ids?
      projects = projects.with_project_type(filter.project_type_ids) if filter.project_type_numbers.any?
      organizations = GrdaWarehouse::Hud::Organization.joins(:projects).merge(projects).distinct
      inventories = GrdaWarehouse::Hud::Inventory.where('1=0')
      project_cocs = GrdaWarehouse::Hud::ProjectCoc.where('1=0')
      funders = GrdaWarehouse::Hud::Funder.where('1=0')

      xlsx = WarehouseReports::HmisCrossWalksController.render(
        layout: nil,
        template: 'warehouse_reports/hmis_cross_walks/index',
        formats: [:xlsx],
        assigns: {
          projects: projects,
          organizations: organizations,
          inventories: inventories,
          project_cocs: project_cocs,
          funders: funders,
        },
      )

      @workbook = ::Roo::Excelx.new(StringIO.new(xlsx).binmode)
    end

    def projects_csv_stream
      StringIO.new(@workbook.sheet('Projects').to_csv)
    end

    def orgs_csv_stream
      StringIO.new(@workbook.sheet('Organizations').to_csv)
    end
  end
end
