###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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
    def perform(client_ids: nil)
      with_lock do
        scope = destination_client_scope
        scope = scope.where(id: client_ids) unless client_ids.nil?
        scope.find_in_batches do |batch|
          values = []
          batch.each do |client|
            result = process_client(client)
            values << result if result
          end
          GrdaWarehouse::ClientRoiAuthorization.import(
            values,
            on_duplicate_key_update: {
              conflict_target: [:destination_client_id],
              columns: values.first&.keys&.excluding(:destination_client_id),
            },
          )
        end
        # cleanup orphans
        orphan_scope = GrdaWarehouse::ClientRoiAuthorization.
          where.not(destination_client_id: destination_client_scope.select(:id))
        orphan_scope = orphan_scope.where(destination_client_id: client_ids) if client_ids
        orphan_scope.delete_all
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
