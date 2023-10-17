###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class MergeClients < BaseMutation
    argument :client_ids, [ID], required: true

    field :client, Types::HmisSchema::Client, null: true

    def resolve(client_ids:)
      raise 'not allowed' unless current_user.can_merge_clients?

      clients = Hmis::Hud::Enrollment.viewable_by(current_user).where(id: client_ids)
      raise 'not found' unless clients.size == client_ids.uniq.length

      Hmis::MergeClientsJob.perform_now(client_ids: client_ids, actor_id: current_user.ids)

      retained_client = Hmis::Hud::Client.where(id: client_ids).first
      raise 'merge failed' unless retained_client.present?

      { client: retained_client }
    end
  end
end
