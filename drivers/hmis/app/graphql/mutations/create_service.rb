module Mutations
  class CreateService < BaseMutation
    argument :input, [Types::HmisSchema::ServiceInput], required: true

    field :service, Types::HmisSchema::Service, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false

    def validate_input(input:)
      errors = []
      errors << InputValidationError.new("Enrollment with id '#{input.enrollment_id}' does not exist", attribute: 'enrollment_id') unless Hmis::Hud::Enrollment.viewable_by(current_user).exists?(id: input.enrollment_id)
      errors << InputValidationError.new("Client with id '#{input.client_id}' does not exist", attribute: 'client_id') unless Hmis::Hud::Client.viewable_by(current_user).exists?(id: input.client_id)
      errors
    end

    def resolve(input:)
      user = hmis_user
      errors = validate_input(input)

      if errors.present?
        return {
          service: nil,
          errors: errors,
        }
      end

      service = Hmis::Hud::Service.new(data_source_id: user.data_source_id, **input.to_params)

      if service.valid?
        service.save!
      else
        errors = service.errors
        service = nil
      end

      {
        service: service,
        errors: errors,
      }
    end
  end
end
