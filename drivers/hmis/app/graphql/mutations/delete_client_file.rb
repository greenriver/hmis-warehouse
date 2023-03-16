module Mutations
  class DeleteClientFile < BaseMutation
    argument :file_id, ID, required: true

    field :client, Types::HmisSchema::Client, null: true

    def resolve(file_id:)
      file = Hmis::File.find_by(id: file_id)
     default_delete_record(
        record: file,
        field_name: :file,
        permissions: :can_manage_client_files,
      )
   end
  end
end
