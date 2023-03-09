module Mutations
  class DeleteService < BaseMutation
    argument :id, ID, required: true

    field :service, Types::HmisSchema::Service, null: true

    def resolve(id:)
      # ID should be a HmisService view ID, which starts with 1 or 2.
      return { errors: [HmisErrors::Error.new(:service, :not_found)] } if id.length < 2 || !['1', '2'].include?(id.first)

      hmis_service = Hmis::Hud::HmisService.viewable_by(current_user).find_by(id: id)
      result = default_delete_record(
        record: hmis_service&.owner,
        field_name: :service,
        permissions: :can_edit_enrollments,
      )

      # Return the HmisService object
      result[:service] = hmis_service.reload if result[:service].present?

      result
    end
  end
end
