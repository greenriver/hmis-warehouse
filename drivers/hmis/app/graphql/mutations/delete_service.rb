module Mutations
  class DeleteService < BaseMutation
    argument :id, ID, required: true

    field :service, Types::HmisSchema::Service, null: true

    def resolve(id:)
      record = Hmis::Hud::Service.editable_by(current_user).find_by(id: id)
      default_delete_record(record: record, field_name: :service)
    end
  end
end
