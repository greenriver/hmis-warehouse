module GrdaWarehouse
  class ProjectGroup < GrdaWarehouseBase
    include ArelHelper
    acts_as_paranoid
    has_paper_trail

    has_and_belongs_to_many :projects, 
      class_name: GrdaWarehouse::Hud::Project.name,
      join_table: :project_project_groups

    has_many :data_quality_reports, 
      class_name: GrdaWarehouse::WarehouseReports::Project::DataQuality::Base.name
    has_one :current_data_quality_report, -> do
      where(processing_errors: nil).where.not(completed_at: nil).order(created_at: :desc).limit(1)
    end, class_name: GrdaWarehouse::WarehouseReports::Project::DataQuality::Base.name

    has_many :contacts, through: :projects
    has_many :organization_contacts, through: :projects


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