module Mutations
  class UpdateClient < BaseMutation
    argument :id, ID, required: true
    argument :input, Types::HmisSchema::ClientInput, required: true

    field :client, Types::HmisSchema::Client, null: true

    def resolve(id:, input:)
      record = Hmis::Hud::Client.visible_to(current_user).find_by(id: id)
      default_update_record(
        record: record,
        field_name: :client,
        input: input,
        permissions: [:can_edit_clients],
      )
    end
  end
end
