module Mutations
  class UpdateFunder < BaseMutation
    # includes InventoryMutation
    argument :id, ID, required: true
    argument :input, Types::HmisSchema::FunderInput, required: true

    field :funder, Types::HmisSchema::Funder, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false

    def resolve(id:, input:)
      record = Hmis::Hud::Funder.viewable_by(current_user).find_by(id: id)
      default_update_record(
        record: record,
        field_name: :funder,
        input: input,
      )
    end
  end
end
