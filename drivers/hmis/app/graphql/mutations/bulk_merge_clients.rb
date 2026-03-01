###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class BulkMergeClients < BaseMutation
    argument :input, [Types::HmisSchema::ClientMergeInput], required: true
    field :success, Boolean, null: true

    def resolve(input:)
      access_denied! unless policy_for(Hmis::Hud::Client, policy_type: :hmis_client).can_merge_clients?

      all_client_ids = input.map(&:client_ids).flatten.uniq
      clients = Hmis::Hud::Client.viewable_by(current_user).where(id: all_client_ids)
      raise 'not found' unless clients.size == all_client_ids.size

      Hmis::Hud::Client.transaction do
        input.each do |obj|
          next unless obj.client_ids.size > 1

          Hmis::MergeClientsJob.perform_now(client_ids: obj.client_ids, actor_id: current_user.id)
        end
      end

      { success: true }
    end
  end
end
