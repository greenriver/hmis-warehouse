###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class HmisSchema::MergeAuditEvent < Types::BaseObject
    field :id, ID, null: false
    field :merged_at, GraphQL::Types::ISO8601DateTime, null: false
    field :pre_merge_state, Types::JsonObject, null: false
    field :user, Application::User, null: true
    field :client_ids_merged, [ID], null: false
    field :client, HmisSchema::Client, null: true

    # object is a Hmis::ClientMergeAudit

    available_filter_options do
      arg :user, [ID]
    end

    def user
      load_ar_association(object, :actor)
    end

    def client_ids_merged
      object.pre_merge_state.map { |attrs| attrs['id'] }
    end

    def client
      load_ar_association(object, :retained_client)
    end
  end
end
