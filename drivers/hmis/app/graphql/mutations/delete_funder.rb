module Mutations
  class DeleteFunder < BaseMutation
    argument :id, ID, required: true

    field :funder, Types::HmisSchema::Funder, null: true

    def resolve(id:)
      record = Hmis::Hud::Funder.editable_by(current_user).find_by(id: id)
      default_delete_record(record: record, field_name: :funder)
    end
  end
end
