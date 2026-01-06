###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class DeleteClientImage < BaseMutation
    argument :client_id, ID, required: true

    field :client, Types::HmisSchema::Client, null: true

    def resolve(client_id:)
      client = Hmis::Hud::Client.visible_to(current_user).find_by(id: client_id)
      access_denied! unless client && policy_for(client, policy_type: :hmis_client).can_edit?

      client.delete_image
      client = client.reload

      {
        client: client,
        errors: [],
      }
    end
  end
end
