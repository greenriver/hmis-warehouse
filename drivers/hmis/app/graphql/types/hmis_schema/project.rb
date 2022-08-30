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
    field :project_name, String, method: :ProjectName, null: false
    field :project_type, Types::HmisSchema::ProjectType, method: :ProjectType, null: false
    field :organization, Types::HmisSchema::Organization, null: false

    def organization
      load_ar_association(object, :organization)
    end
  end
end
