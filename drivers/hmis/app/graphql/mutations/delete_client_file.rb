###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class DeleteClientFile < BaseMutation
    argument :file_id, ID, required: true

    field :file, Types::HmisSchema::File, null: true

    def resolve(file_id:)
      file = Hmis::File.viewable_by(current_user).find_by(id: file_id)
      # TODO(#8999): use HmisClientFilePolicy
      access_denied! unless file && Hmis::File.authorize_proc.call(file, current_user)

      file.destroy!
      {
        file: file,
        errors: [],
      }
    end
  end
end
