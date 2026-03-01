###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class DeleteClientAlert < CleanBaseMutation
    argument :id, ID, required: true

    field :client_alert, Types::HmisSchema::ClientAlert, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false, resolver: Resolvers::ValidationErrors

    def resolve(id:)
      record = Hmis::ClientAlert.find(id)
      access_denied! unless policy_for(record.client, policy_type: :hmis_client).can_manage_alerts?

      record.destroy!

      {
        client_alert: record,
        errors: [],
      }
    end
  end
end
