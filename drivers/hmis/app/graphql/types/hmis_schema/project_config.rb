###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::ProjectConfig < Types::BaseObject
    description 'Project Config'
    field :id, ID, null: false
    field :config_type, Types::HmisSchema::Enums::ProjectConfigType, null: false, method: :type
    field :config_options, GraphQL::Types::JSON, null: true
    field :project_type, Types::HmisSchema::Enums::ProjectType, null: true
    field :project_id, ID, null: true
    field :project, HmisSchema::Project, null: true
    field :organization_id, ID, null: true
    field :organization, HmisSchema::Organization, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    # object is a Hmis::ProjectConfig

    available_filter_options do
      arg :config_type, [Types::HmisSchema::Enums::ProjectConfigType]
      arg :project, [ID]
    end

    def project
      load_ar_association(object, :project)
    end

    def organization
      load_ar_association(object, :organization)
    end
  end
end
