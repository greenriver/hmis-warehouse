###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class UpdateClientImage < BaseMutation
    argument :client_id, ID, required: true
    argument :image_blob_id, ID, required: true
    argument :lock_version, Integer, required: false

    field :client, Types::HmisSchema::Client, null: true

    def resolve(client_id:, image_blob_id:, lock_version: nil)
      client = Hmis::Hud::Client.visible_to(current_user).find_by(id: client_id)

      raise HmisErrors::ApiError, 'Record not found' unless client.present?
      raise HmisErrors::ApiError, 'Access denied' unless current_user.permissions_for?(client, :can_edit_clients)

      client.image_blob_id = image_blob_id
      client.lock_version = lock_version if lock_version
      client.save!
      client = client.reload

      {
        client: client,
        errors: [],
      }
    end
  end
end
