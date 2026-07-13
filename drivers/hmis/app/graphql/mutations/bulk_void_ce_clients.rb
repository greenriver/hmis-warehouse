###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class BulkVoidCeClients < CleanBaseMutation
    argument :destination_client_ids, [ID], required: true

    field :success, Boolean, null: false, description: 'True if the bulk void was queued for processing. Does not indicate the job successfully completed.'

    def resolve(destination_client_ids:)
      # Check for user's CE admin permission. (Bypass project-level permissions to view clients or edit enrollments)
      access_denied! unless policy_for(Hmis::Ce::Opportunity, policy_type: :ce_opportunity).can_bulk_void_ce_clients?

      return { success: true } if destination_client_ids.empty?

      # Confirm all clients in the input exist before kicking off the job
      source_client_ids = Hmis::WarehouseClient.
        where(data_source_id: current_user.hmis_data_source_id, destination_id: destination_client_ids).
        select(:source_id)
      clients_count = Hmis::Hud::Client.where(data_source_id: current_user.hmis_data_source_id, id: source_client_ids).count
      access_denied! if destination_client_ids.count != clients_count

      queue = ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)
      HmisExternalApis::AcHmis::BulkVoidCeClientsJob.
        set(priority: BaseJob::UI_IMMEDIATE_PRIORITY_NEG5, queue: queue).
        perform_later(destination_client_ids: destination_client_ids, data_source_id: current_user.hmis_data_source_id, initiated_by_id: current_user.id)

      { success: true }
    end
  end
end
