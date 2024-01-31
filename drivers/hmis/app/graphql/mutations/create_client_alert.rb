module Mutations
  class CreateClientAlert < CleanBaseMutation
    argument :input, Types::HmisSchema::ClientAlertInput, required: true

    field :client_alert, Types::HmisSchema::ClientAlert, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false, resolver: Resolvers::ValidationErrors

    def resolve(input:)
      client = Hmis::Hud::Client.find(input.client_id)
      raise 'not allowed' unless current_permission?(permission: :can_manage_client_alerts, entity: client)

      params = input.to_params
      alert = Hmis::ClientAlert.new(params)
      alert.created_by = current_user

      if alert.valid?
        alert.save!
        { client_alert: alert }
      else
        errors = HmisErrors::Errors.new
        errors.add_ar_errors(alert.errors)
        { errors: errors }
      end
    end
  end
end
