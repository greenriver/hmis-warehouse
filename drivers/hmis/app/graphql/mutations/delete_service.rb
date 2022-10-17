module Mutations
  class DeleteService < BaseMutation
    argument :id, ID, required: true

    field :service, Types::HmisSchema::Service, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false

    def resolve(id:)
      # TODO viewable by
      record = Hmis::Hud::Service.find_by(id: id)
      default_delete_record(record: record, field_name: :service)
    end
  end
end
