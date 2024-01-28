###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class MergeClients < BaseMutation
    argument :client_ids, [ID], required: true

    field :client, Types::HmisSchema::Client, null: true

    def resolve(client_ids:)
      raise 'not allowed' unless current_user.can_merge_clients?

      clients = Hmis::Hud::Client.viewable_by(current_user).where(id: client_ids)
      raise 'not found' unless clients.size == client_ids.uniq.length

      Hmis::MergeClientsJob.perform_now(client_ids: client_ids, actor_id: current_user.id)

      retained_clients = Hmis::Hud::Client.where(id: client_ids)
      raise 'merge failed' unless retained_clients.size == 1

      { client: retained_clients.first }
    end
  end
end
