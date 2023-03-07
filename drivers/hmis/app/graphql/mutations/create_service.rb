module Mutations
  class CreateService < BaseMutation
    argument :input, Types::HmisSchema::ServiceInput, required: true

    field :service, Types::HmisSchema::Service, null: true

    def validate_input(input)
      errors = []
      params = input.to_params
      errors << HmisErrors::Error.new(:enrollment_id, :not_found) unless params[:enrollment_id].present?
      errors
    end

    def resolve(input:)
      errors = validate_input(input)
      return { errors: errors } if errors.any?

      default_create_record(
        Hmis::Hud::Service,
        field_name: :service,
        id_field_name: :services_id,
        input: input,
        permissions: [:can_edit_enrollments],
      )
    end
  end
end
