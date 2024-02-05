###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class DeleteClientFile < BaseMutation
    argument :file_id, ID, required: true

    field :file, Types::HmisSchema::File, null: true

    def resolve(file_id:)
      file = Hmis::File.find_by(id: file_id)
      default_delete_record(
        record: file,
        field_name: :file,
        permissions: :can_manage_any_client_files,
        authorize: Hmis::File.authorize_proc,
      )
    end
  end
end
