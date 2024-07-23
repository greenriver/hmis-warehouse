###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis::Migration
  class InitialMciUniqueIdCreationJob < BaseJob
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)
    def perform(clobber: false)
      delete_all_mci_uniq_ids! if clobber

      create_mci_unique_ids_from_personal_ids
    end

    private

    def delete_all_mci_uniq_ids!
      HmisExternalApis::ExternalId.for_clients.where(namespace: mci_uniq_namespace).delete_all
    end

    # Create initial set of MCI Unique IDs based on the Personal IDs.
    # This works because the HUD CSV export we get from the AC Warehouse
    # contains MCI Unique IDs in the Personal ID column.
    def create_mci_unique_ids_from_personal_ids
      data_source_id = GrdaWarehouse::DataSource.hmis.first&.id
      raise 'No HMIS Data Source' unless data_source_id.present?

      ac_warehouse_cred = ::GrdaWarehouse::RemoteCredential.active.
        find_by(slug: HmisExternalApis::AcHmis::DataWarehouseApi::SYSTEM_ID)
      raise 'No remote credential for MCI Unique ID' unless ac_warehouse_cred.present?

      # { Client ID => Personal ID }
      hmis_client_lookup = Hmis::Hud::Client.where(data_source_id: data_source_id).
        pluck(:id, :personal_id).to_h

      skipped_personal_ids = []

      mci_unique_ids = hmis_client_lookup.map do |client_id, personal_id|
        unless personal_id.scan(/\D/).empty? # ignore non-numeric values
          skipped_personal_ids << personal_id
          next
        end

        {
          value: personal_id,
          source_type: 'Hmis::Hud::Client',
          source_id: client_id,
          namespace: mci_uniq_namespace,
          # Use the AC Data Warehouse credential as the remote credentials,
          # since that's where it originally came from. In the future when we
          # are getting MCI Unique Ids using the WarehouseChangesJob, it will
          # be using this credential.
          remote_credential_id: ac_warehouse_cred.id,
        }
      end.compact

      HmisExternalApis::ExternalId.import!(mci_unique_ids, on_duplicate_key_ignore: true)

      Rails.logger.info "Created #{mci_unique_ids.size} MCI Unique IDs from Personal IDs. Skipped #{skipped_personal_ids.count} Personal IDs that were likely not MCI Unique IDs."
      Rails.logger.info "Skipped Personal IDs: #{skipped_personal_ids.take(30)}" if skipped_personal_ids.any?
    end

    def mci_uniq_namespace
      HmisExternalApis::AcHmis::WarehouseChangesJob::NAMESPACE
    end
  end
end
