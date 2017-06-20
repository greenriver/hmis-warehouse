module GrdaWarehouse
  class ProjectGroup < GrdaWarehouseBase
    include ArelHelper
    acts_as_paranoid
    has_paper_trail

    has_and_belongs_to_many :projects, 
      class_name: GrdaWarehouse::Hud::Project.name,
      join_table: :project_project_groups

    has_many :data_quality_reports, 
      class_name: GrdaWarehouse::WarehouseReports::Project::DataQuality::Base

    has_many :contacts, through: :projects


    def self.available_projects
      GrdaWarehouse::Hud::Project.joins(:organization).
        pluck(:ProjectName, o_t[:OrganizationName].as('organization_name').to_sql, :id).
        map do |project_name, organization_name, id|
          [
            "#{project_name} < #{organization_name}",
            id
          ]
        end
    end
  end
end