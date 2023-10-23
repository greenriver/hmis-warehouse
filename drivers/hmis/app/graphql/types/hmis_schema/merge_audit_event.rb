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
    field :user, HmisSchema::User, null: true
    field :client_ids_merged, [ID], null: false

    # object is a Hmis::ClientMergeAudit

    def user
      application_user = load_ar_association(object, :actor)
      application_user.hmis_data_source_id = current_user.hmis_data_source_id
      Hmis::Hud::User.from_user(application_user)
    end

    def client_ids_merged
      object.pre_merge_state.map { |attrs| attrs['id'] }
    end
  end
end
