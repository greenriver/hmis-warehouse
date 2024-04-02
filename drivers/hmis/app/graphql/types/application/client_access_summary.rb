###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class Application::ClientAccessSummary < Types::BaseObject
    # maps to Hmis::ClientAccessSummary
    graphql_name 'ClientAccessSummary'
    field :id, ID, null: false
    field :last_accessed_at, GraphQL::Types::ISO8601DateTime, null: false
    field :client_id, ID, null: false
    field :client_name, String, null: true

    def client_name
      return client&.masked_name unless current_permission?(permission: :can_view_client_name, entity: client)

      client&.brief_name
    end

    def client
      load_ar_association(object, :client, scope: Hmis::Hud::Client.with_deleted)
    end

    available_filter_options do
      arg :search_term, String
      arg :on_or_after, GraphQL::Types::ISO8601Date
    end
  end
end
