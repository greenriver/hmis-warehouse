###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Project < Types::BaseObject
    description 'HUD Project'
    field :id, ID, null: false
    field :name, String, null: false
    field :project_type, Types::HmisSchema::ProjectType, null: false

    def self.projects(context, project_types)
      viewable_projects = GrdaWarehouse::Hud::Project.viewable_by(context[:current_user])
      viewable_projects = viewable_projects.with_project_type(project_types) if project_types.present?

      # TODO: Adapters to  separate GraphQL types from ActiveRecord models
      viewable_projects.distinct.all.map { |p| { id: p.ProjectID, name: p.ProjectName, project_type: p.ProjectType } }
    end
  end
end
