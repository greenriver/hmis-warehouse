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
    field :organization, Types::HmisSchema::Organization, null: true

    def name
      object.name(context[:current_user])
    end

    def project_type
      object.ProjectType
    end
  end
end
