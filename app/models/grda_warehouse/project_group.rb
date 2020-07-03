###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class ProjectGroup < GrdaWarehouseBase
    include ArelHelper
    include AccessGroups
    acts_as_paranoid
    has_paper_trail

    has_and_belongs_to_many :projects,
      class_name: 'GrdaWarehouse::Hud::Project',
      join_table: :project_project_groups

    has_many :data_quality_reports,
      class_name: 'GrdaWarehouse::WarehouseReports::Project::DataQuality::Base'
    has_one :current_data_quality_report, -> do
      where(processing_errors: nil).where.not(completed_at: nil).order(created_at: :desc).limit(1)
    end, class_name: 'GrdaWarehouse::WarehouseReports::Project::DataQuality::Base'

    has_many :contacts, through: :projects
    has_many :organization_contacts, through: :projects

    scope :viewable_by, -> (user) do
      if user.can_edit_project_groups?
        current_scope
      else
        if current_scope.present?
          current_scope.merge(user.project_groups)
        else
          user.project_groups
        end
      end
    end
    scope :editable_by, -> (user) do
      viewable_by(user)
    end

    def self.available_projects(user)
      GrdaWarehouse::Hud::Project.viewable_by(user).
        joins(:organization).
        map do |project|
          [
            project.organization_and_name,
            project.id,
          ]
        end
    end

    def self.options_for_select(user:)
      viewable_by(user).distinct.order(name: :asc).pluck(:name, :id)
    end
  end
end