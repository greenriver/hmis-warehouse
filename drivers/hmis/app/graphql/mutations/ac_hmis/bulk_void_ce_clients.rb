###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class AcHmis::BulkVoidCeClients < CleanBaseMutation
    argument :destination_client_ids, [ID], required: true
    argument :project_id, ID, required: true

    field :success, Boolean, null: false, description: 'True if the bulk void was queued for processing. Does not indicate the job successfully completed.'

    def resolve(destination_client_ids:, project_id:)
      access_denied! unless policy_for(Hmis::Ce::Opportunity, policy_type: :ce_opportunity).can_bulk_void_ce_clients?

      project = Hmis::Hud::Project.ce_bulk_voidable_by(current_user).find_by(id: project_id)
      access_denied! unless project

      return { success: true } if destination_client_ids.empty?

      # Confirm all clients in the input exist and are viewable by the user before kicking off the job.
      # A destination (warehouse) client can map to more than one source client in the data source
      # (e.g. after a merge), so check that every requested destination id resolves to at least one
      # viewable source client rather than comparing raw counts.
      viewable_source_ids = Hmis::Hud::Client.viewable_by(current_user).
        where(data_source_id: current_user.hmis_data_source_id).
        select(:id)
      viewable_destination_ids = Hmis::WarehouseClient.
        where(data_source_id: current_user.hmis_data_source_id, source_id: viewable_source_ids, destination_id: destination_client_ids).
        distinct.
        pluck(:destination_id)
      missing_destination_ids = destination_client_ids.map(&:to_i).uniq - viewable_destination_ids
      access_denied! if missing_destination_ids.any?

      queue = ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)
      HmisExternalApis::AcHmis::BulkVoidCeClientsJob.
        set(priority: BaseJob::UI_IMMEDIATE_PRIORITY_NEG5, queue: queue).
        perform_later(destination_client_ids: destination_client_ids, ce_project_id: project.id, initiated_by_id: current_user.id)

      { success: true }
    end
  end
end
