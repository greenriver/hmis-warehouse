###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::AutoExitConfig < Types::BaseObject
    include HmisSchema::HasFlatProjectAndOrganization
    description 'Auto Exit Config'
    field :id, ID, null: false
    field :length_of_absence_days, Int, null: false
    field :project_type, Types::HmisSchema::Enums::ProjectType, null: true
    flat_project_and_organization_fields(nullable: true, skip_project_type: true)
  end
end
