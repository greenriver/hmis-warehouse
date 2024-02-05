#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module Mutations
  class DeleteClientAlert < CleanBaseMutation
    argument :id, ID, required: true

    field :client_alert, Types::HmisSchema::ClientAlert, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false, resolver: Resolvers::ValidationErrors

    def resolve(id:)
      record = Hmis::ClientAlert.find(id)
      raise 'Access denied' unless current_permission?(permission: :can_manage_client_alerts, entity: record.client)

      record.destroy!

      {
        client_alert: record,
        errors: [],
      }
    end
  end
end
