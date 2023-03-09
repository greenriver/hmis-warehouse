module Mutations
  class UpdateService < BaseMutation
    argument :id, ID, required: true
    argument :input, Types::HmisSchema::ServiceInput, required: true

    field :service, Types::HmisSchema::Service, null: true

    def resolve(id:, input:)
      record = Hmis::Hud::Service.viewable_by(current_user).find_by(id: id)
      default_update_record(
        record: record,
        field_name: :service,
        input: input,
        permissions: [:can_edit_enrollments],
      )
    end
  end
end
