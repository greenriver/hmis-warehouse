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
      file = Hmis::File.find_by(id: file_id) # TODO - only include files that the user can view.
      # Can't use viewable_by scope since it includes confidential files even if the user can only view nonconfidential

      raise HmisErrors::ApiError, 'Record not found' unless file.present?
      raise HmisErrors::ApiError, 'Access denied' unless policy_for(file.client, policy_type: :hmis_client).can_edit_client_file?(file: file)

      file.destroy!

      {
        file: file,
        errors: [],
      }
    end
  end
end
