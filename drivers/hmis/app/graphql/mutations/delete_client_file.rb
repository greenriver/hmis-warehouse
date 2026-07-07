###
# Copyright Green River Data Group, Inc.
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
      access_denied! unless file && current_user.policy_for(file, policy_type: :hmis_file).can_delete?

      file.destroy!
      {
        file: file,
        errors: [],
      }
    end
  end
end
