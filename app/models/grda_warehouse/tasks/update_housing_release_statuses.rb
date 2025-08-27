###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  module Tasks
    class UpdateHousingReleaseStatuses
      include ArelHelper

      def run!
        # Use optimized batch processing with preloaded associations
        GrdaWarehouse::Hud::Client.destination.
          preload(:client_files).
          find_in_batches(batch_size: 1000) do |clients|
            process_client_batch(clients)
          end
      end

      def process_client_batch(clients)
        # Group clients by their calculated status for bulk updates
        status_groups = {}

        clients.each do |client|
          consent_class = GrdaWarehouse::Config.active_consent_class.new(client: client)

          old_status = client.housing_release_status
          new_status = consent_class.current_consent_type

          if new_status != old_status
            status_groups[new_status] ||= []
            status_groups[new_status] << { id: client.id, old_status: old_status }
          end
        end

        # Perform bulk updates by status
        status_groups.each do |new_status, client_updates|
          client_ids = client_updates.map { |update| update[:id] }

          GrdaWarehouse::Hud::Client.where(id: client_ids).
            update_all(housing_release_status: new_status)

          # Regenerate ROI authorizations for affected clients
          GrdaWarehouse::Tasks::GenerateClientRoiAuthorizationsTask.new.perform(client_ids: client_ids)
        end
      end

      # private def calculate_consent_status(client)
      #   # Use the active consent class to calculate the current status
      #   consent_class = GrdaWarehouse::Config.active_consent_class.new(client: client)

      #   # Get the base status without COC codes or expiration info
      #   base_status = case consent_class.release_current_status
      #   when consent_class.full_release_string
      #     consent_class.full_release_string
      #   when consent_class.revoked_consent_string
      #     consent_class.revoked_consent_string
      #   when consent_class.partial_release_string
      #     consent_class.partial_release_string
      #   else
      #     consent_class.no_release_string
      #   end

      #   base_status
      # end
    end
  end
end
