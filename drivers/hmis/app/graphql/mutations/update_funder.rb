module Mutations
  class UpdateFunder < BaseMutation
    argument :id, ID, required: true
    argument :input, Types::HmisSchema::FunderInput, required: true

    field :funder, Types::HmisSchema::Funder, null: true

    def resolve(id:, input:)
      record = Hmis::Hud::Funder.editable_by(current_user).find_by(id: id)
      default_update_record(
        record: record,
        field_name: :funder,
        input: input,
      )
    end
  end
end
