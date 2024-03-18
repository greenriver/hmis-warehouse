###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::ProjectConfig < Types::BaseObject
    description 'Project Config'
    field :id, ID, null: false
    field :config_type, Types::HmisSchema::Enums::ProjectConfigType, null: false
    field :config_options, GraphQL::Types::JSON, null: true
    field :project_type, Types::HmisSchema::Enums::ProjectType, null: true
    field :project_id, ID, null: true
    field :project, HmisSchema::Project, null: true
    field :organization_id, ID, null: true
    field :organization, HmisSchema::Organization, null: true

    def project
      load_ar_association(object, :project)
    end

    def organization
      load_ar_association(object, :organization)
    end
  end
end
