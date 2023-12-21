###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class Application::ClientAccessSummary < Types::BaseObject
    # maps to Hmis::ClientAccessSummary
    graphql_name 'ClientAccessSummary'
    field :id, ID, null: false
    field :last_accessed_at, GraphQL::Types::ISO8601DateTime, null: false
    field :client, HmisSchema::Client, null: true

    def client
      load_ar_association(object, :client)
    end
  end
end
