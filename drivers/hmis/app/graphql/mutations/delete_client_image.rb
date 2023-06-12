###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class DeleteClientImage < BaseMutation
    argument :client_id, ID, required: true

    field :client, Types::HmisSchema::Client, null: true

    def resolve(client_id:)
      client = Hmis::Hud::Client.visible_to(current_user).find_by(id: client_id)
      raise HmisErrors::ApiError, 'Record not found' unless client.present?
      raise HmisErrors::ApiError, 'Access denied' unless current_user.permissions_for?(client, :can_edit_clients)

      client.delete_image
      client = client.reload

      {
        client: client,
        errors: [],
      }
    end
  end
end
