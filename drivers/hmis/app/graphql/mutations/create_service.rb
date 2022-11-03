module Mutations
  class CreateService < BaseMutation
    argument :input, Types::HmisSchema::ServiceInput, required: true

    field :service, Types::HmisSchema::Service, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false

    def validate_input(input)
      errors = []
      params = input.to_params
      errors << InputValidationError.new("Enrollment with id '#{input.enrollment_id}' does not exist", attribute: 'enrollment_id') unless Hmis::Hud::Enrollment.editable_by(current_user).exists?(enrollment_id: params[:enrollment_id].to_i)
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

      service = Hmis::Hud::Service.new(
        services_id: Hmis::Hud::Service.generate_services_id,
        data_source_id: user.data_source_id,
        user_id: user.user_id,
        date_updated: DateTime.current,
        date_created: DateTime.current,
        **input.to_params,
      )

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
