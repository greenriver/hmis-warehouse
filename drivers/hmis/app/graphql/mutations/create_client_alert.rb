module Mutations
  class CreateClientAlert < CleanBaseMutation
    argument :input, Types::HmisSchema::ClientAlertInput, required: true

    field :client_alert, Types::HmisSchema::ClientAlert, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false, resolver: Resolvers::ValidationErrors

    def resolve(input:)
      client = Hmis::Hud::Client.find(input.client_id)
      raise 'not allowed' unless current_permission?(permission: :can_manage_client_alerts, entity: client)

      default_create_record(
        Hmis::ClientAlert,
        field_name: :client_alert,
        input: input,
        permissions: [:can_manage_client_alerts],
        exclude_default_fields: true,
      )
    end
  end
end
