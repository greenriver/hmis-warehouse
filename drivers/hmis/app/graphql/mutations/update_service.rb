module Mutations
  class UpdateService < BaseMutation
    argument :id, ID, required: true
    argument :input, Types::HmisSchema::ServiceInput, required: true

    field :service, Types::HmisSchema::Service, null: true

    def resolve(id:, input:)
      # ID should be a HmisService view ID, which starts with 1 or 2.
      return { errors: [HmisErrors::Error.new(:service, :not_found)] } if id.length < 2 || !['1', '2'].include?(id.first)

      hmis_service = Hmis::Hud::HmisService.viewable_by(current_user).find_by(id: id)
      result = default_update_record(
        record: hmis_service&.owner,
        field_name: :service,
        input: input,
        permissions: [:can_edit_enrollments],
      )

      # Return the HmisService object
      result[:service] = hmis_service.reload if result[:service].present?

      result
    end
  end
end
