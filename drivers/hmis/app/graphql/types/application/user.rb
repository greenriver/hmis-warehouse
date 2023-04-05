###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Application::User < Types::BaseObject
    description 'User account for a user of the system'
    graphql_name 'ApplicationUser'
    field :id, ID, null: false
    field :name, String, null: false
    field :recent_items, [Types::HmisSchema::OmnisearchResult], null: false
    field :date_updated, GraphQL::Types::ISO8601DateTime, null: false
    field :date_created, GraphQL::Types::ISO8601DateTime, null: false
    field :date_deleted, GraphQL::Types::ISO8601DateTime, null: true

    def name
      [object.first_name, object.last_name].compact.join(' ')
    end

    def recent_items
      # Only allow this if fetching our own recent items
      return [] unless current_user == object

      current_user.recent_items
    end
  end
end
