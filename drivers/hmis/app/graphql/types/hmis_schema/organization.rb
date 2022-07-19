###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Organization < Types::BaseObject
    include Types::HmisSchema::HasProjects

    description 'HUD Organization'
    field :id, ID, null: false
    field :organization_name, String, method: :OrganizationName, null: false
    projects_field :projects, 'Get a list of projects for this organization'

    def projects(**args)
      resolve_projects(object.projects, **args)
    end

    def self.organizations(scope = Hmis::Hud::Organization.all, user:)
      scope.viewable_by(user)
    end
  end
end
