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

      errors = HmisErrors::Errors.new
      errors.add :note, :required if input.note.blank?
      errors.add :priority, :required unless input.priority
      errors.add :expiration_date, :required unless input.expiration_date
      errors.add :expiration_date, :invalid, full_message: 'Expiration date must be in the future.' if input.expiration_date && !input.expiration_date.future?
      # Use 3650 days (not 10 years) to match simple 'offset' logic in static form
      errors.add :expiration_date, :invalid, full_message: 'Expiration date must not be more than 10 years in the future.' if input.expiration_date && input.expiration_date > Date.today + 3650.days

      return { errors: errors } if errors.any?

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
