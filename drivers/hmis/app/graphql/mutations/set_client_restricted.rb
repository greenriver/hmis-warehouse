###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class SetClientRestricted < CleanBaseMutation
    argument :client_id, ID, required: true
    argument :restricted, Boolean, required: true

    field :client, Types::HmisSchema::Client, null: true

    def resolve(client_id:, restricted:)
      client = Hmis::Hud::Client.viewable_by(current_user).find_by(id: client_id)
      access_denied! unless client && policy_for(client, policy_type: :hmis_client).can_mark_restricted?

      if restricted
        client.mark_as_restricted!(user: current_user)
      else
        client.remove_restriction!
      end

      { client: client }
    end
  end
end
