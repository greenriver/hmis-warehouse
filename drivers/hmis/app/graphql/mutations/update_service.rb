module Mutations
  class UpdateService < BaseMutation
    argument :id, ID, required: true
    argument :input, Types::HmisSchema::ServiceInput, required: true

    field :service, Types::HmisSchema::Service, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false

    def resolve(id:, input:)
      errors = []
      service = Hmis::Hud::Service.find_by(id: id)

      if service.present?
        service.update(**input.to_params, date_updated: DateTime.current, user_id: hmis_user.user_id)
        errors += service.errors.errors unless service.valid?
      else
        errors << InputValidationError.new("No service found with ID '#{id}'", attribute: 'id') unless service.present?
      end

      {
        service: service&.valid? ? service : nil,
        errors: errors,
      }
    end
  end
end
