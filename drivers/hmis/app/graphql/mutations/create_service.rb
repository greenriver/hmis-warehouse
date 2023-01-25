module Mutations
  class CreateService < BaseMutation
    argument :input, Types::HmisSchema::ServiceInput, required: true

    field :service, Types::HmisSchema::Service, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false

    def validate_input(input)
      errors = []
      params = input.to_params
      errors << InputValidationError.new("Enrollment with id '#{input.enrollment_id}' does not exist", attribute: 'enrollment_id') unless params[:enrollment_id].present?
      errors
    end

    def resolve(input:)
      errors = validate_input(input)
      return { service: nil, errors: errors } if errors.present?

      default_create_record(
        Hmis::Hud::Service,
        field_name: :service,
        id_field_name: :services_id,
        input: input,
      )
    end
  end
end
