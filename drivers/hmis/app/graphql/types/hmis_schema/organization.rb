###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Organization < Types::BaseObject
    include Types::HmisSchema::HasProjects

    def self.configuration
      Hmis::Hud::Organization.hmis_configuration(version: '2022')
    end

    hud_field :id, ID, null: false
    hud_field :organization_name
    projects_field :projects
    hud_field :victim_service_provider, HmisSchema::Enums::Hud::NoYesMissing
    field :description, String, null: true
    field :contact_information, String, null: true
    hud_field :date_updated
    hud_field :date_created
    hud_field :date_deleted

    access_field do
      can :delete_organization
      can :edit_organization
    end

    def projects(**args)
      resolve_projects(object.projects, **args)
    end

    def self.organizations(scope = Hmis::Hud::Organization.all, user:)
      scope.viewable_by(user)
    end
  end
end
