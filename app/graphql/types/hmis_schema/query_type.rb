# frozen_string_literal: true

module Types
  class HmisSchema::QueryType < Types::BaseObject
    # From generated QueryType:
    # Add `node(id: ID!) and `nodes(ids: [ID!]!)`
    include GraphQL::Types::Relay::HasNodeField
    include GraphQL::Types::Relay::HasNodesField

    field :projects, [Types::HmisSchema::Project], 'Get a list of projects' do
      argument :project_types, [Types::HmisSchema::ProjectType], required: false
    end

    def projects(project_types: nil)
      Types::HmisSchema::Project.projects(context, project_types)
    end
  end
end
