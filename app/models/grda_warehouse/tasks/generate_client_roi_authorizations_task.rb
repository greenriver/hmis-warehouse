###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Build ROI values from the client. This task can be removed if we change RoiAuthorizations to be canonical record in
# the future
module GrdaWarehouse::Tasks
  class GenerateClientRoiAuthorizationsTask
    def self.perform(...)
      new.perform(...)
    end

    # @param client_ids [Array<Integer>, nil] client ids to rebuild. Rebuild all clients if nil
    # @param batch_size [Integer] number of records to process in each batch
    def perform(client_ids: nil, batch_size: 500)
      with_lock do
        scope = destination_client_scope
        scope = scope.where(id: client_ids) unless client_ids.nil?
        scope.find_in_batches(batch_size: batch_size) do |batch|
          values = []
          missing_ids = []
          batch.each do |client|
            result = process_client(client)
            missing_ids << client.id if result.nil?
            values << result if result
          end

          GrdaWarehouse::ClientRoiAuthorization.import(
            values,
            on_duplicate_key_update: {
              conflict_target: [:destination_client_id],
              columns: values.first&.keys&.excluding(:destination_client_id),
            },
          )

          # cleanup auth records for clients that have lost ROI status (but client still exists). This might be due to data correction rather than revocation
          GrdaWarehouse::ClientRoiAuthorization.where(destination_client: missing_ids).delete_all
        end

        # cleanup orphaned auth records where the client record no-longer exists at all
        orphan_ids = GrdaWarehouse::ClientRoiAuthorization.with_invalid_client.pluck(:id)
        orphan_ids.each_slice(batch_size) do |ids|
          GrdaWarehouse::ClientRoiAuthorization.where(id: ids).delete_all
        end
      end
    end

    protected

    # we only consider building ROI authorizations for destination clients
    def destination_client_scope
      GrdaWarehouse::Hud::Client.destination
    end

    def process_client(destination_client)
      status = roi_status(destination_client)

      return nil unless status

      {
        status: status,
        destination_client_id: destination_client.id,
        coc_codes: roi_coc_codes(destination_client),
        starts_at: destination_client.consent_form_signed_on,
        expires_at: roi_expiry_date(destination_client),
        # maybe add file, other fields
      }
    end

    def roi_expiry_date(client)
      case roi_duration
      when 'One Year', 'Two Years'
        raise "missing consent form signature on client: #{client.id}" unless client.consent_form_signed_on

        client.consent_form_signed_on + GrdaWarehouse::Hud::Client.consent_validity_period
      when 'Use Expiration Date'
        client.consent_expires_on
      when 'Indefinite'
        nil
      else
        raise "unknown release duration \"#{roi_duration}\""
      end
    end

    def roi_duration
      GrdaWarehouse::Hud::Client.release_duration
    end

    def roi_coc_codes(client)
      result = client.consented_coc_codes&.compact_blank&.presence
      result&.sort&.uniq
    end

    def roi_status(client)
      # skip if the roi is missing a signature date and it's needed to determine the validity period
      return nil if client.consent_form_signed_on.nil? && roi_duration.in?(['One Year', 'Two Years'])

      if client.revoked_consent?
        GrdaWarehouse::ClientRoiAuthorization::REVOKED_STATUS
      elsif client.partial_release?
        GrdaWarehouse::ClientRoiAuthorization::PARTIAL_STATUS
      elsif client.release_valid?
        GrdaWarehouse::ClientRoiAuthorization::FULL_STATUS
      end
    end

    def with_lock(&block)
      lock_name = self.class.name.demodulize
      GrdaWarehouseBase.with_advisory_lock(lock_name, timeout_seconds: 0, &block)
    end
  end
end
