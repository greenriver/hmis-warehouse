###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::QueryType < Types::BaseObject
    # From generated QueryType:
    # Add `node(id: ID!) and `nodes(ids: [ID!]!)`
    include GraphQL::Types::Relay::HasNodeField
    include GraphQL::Types::Relay::HasNodesField
    include Types::HmisSchema::HasProjects
    include Types::HmisSchema::HasOrganizations

    projects_field :projects, description: 'Get a list of projects'

    def projects(**args)
      resolve_projects(Hmis::Hud::Project.all, **args)
    end

    organizations_field :organizations, description: 'Get a list of organizations'

    def organizations(**args)
      resolve_organizations(Hmis::Hud::Organization.all, **args)
    end
  end
end
