###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class BulkMergeClients < BaseMutation
    argument :input, [Types::HmisSchema::ClientMergeInput], required: true
    field :success, Boolean, null: true

    def resolve(input:)
      raise 'not allowed' unless current_user.can_merge_clients?

      all_client_ids = input.map(&:client_ids).flatten.uniq
      clients = Hmis::Hud::Client.viewable_by(current_user).where(id: all_client_ids)
      raise 'not found' unless clients.size == all_client_ids.size

      # kick off jobs
      input.each do |obj|
        next unless obj.client_ids.size > 1

        Hmis::MergeClientsJob.perform_now(client_ids: obj.client_ids, actor_id: current_user.id)
      end

      { success: true }
    end
  end
end
