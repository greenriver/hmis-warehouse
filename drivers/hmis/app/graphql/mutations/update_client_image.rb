###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class UpdateClientImage < BaseMutation
    argument :client_id, ID, required: true
    argument :image_blob_id, ID, required: true

    field :client, Types::HmisSchema::Client, null: true

    def resolve(client_id:, image_blob_id:)
      client = Hmis::Hud::Client.visible_to(current_user).find_by(id: client_id)

      raise HmisErrors::ApiError, 'Record not found' unless client.present?
      raise HmisErrors::ApiError, 'Access denied' unless current_user.permissions_for?(client, :can_edit_clients)

      errors = HmisErrors::Errors.new

      if client.build_client_headshot_file(image_blob_id, current_user)
        client.save!
      else
        errors.add(:base, :invalid, full_message: 'No uploaded file found. The upload may have expired; please try reloading the page and retrying the upload.')
      end

      {
        client: client,
        errors: errors,
      }
    end
  end
end
