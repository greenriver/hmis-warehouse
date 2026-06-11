# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Build ROI values from the client. This task can be removed if we change RoiAuthorizations to be canonical record in
# the future
module GrdaWarehouse::Tasks
  class GenerateClientRoiAuthorizationsTask
    include MaintenanceTaskInstrumentation

    def self.perform(...)
      new.perform(...)
    end

    def perform(...)
      instrument_as_maintenance_task do |run|
        run.complete! if _perform(...)
      end
    end

    # Rebuild ROI authorization records for destination clients. For each client:
    #   - upsert a ClientRoiAuthorization if roi_status returns a value
    #   - delete the authorization and invalidate consent if roi_status returns nil
    #     (covers both data corrections and clients with no consent of any kind)
    # After processing all batches, invalidate consent for clients whose authorization
    # has passed its expiry date, and delete orphaned auth records whose client no longer exists.
    # @param client_ids [Array<Integer>, nil] client ids to rebuild. Rebuild all clients if nil
    # @param batch_size [Integer] number of records to process in each batch
    def _perform(client_ids: nil, batch_size: 500)
      did_run = false
      with_lock do
        did_run = true
        scope = destination_client_scope
        scope = scope.where(id: client_ids) unless client_ids.nil?
        scope.find_in_batches(batch_size: batch_size) do |batch|
          values = []
          # Clients in this batch that have no current ROI status (e.g. data correction removed their consent)
          no_roi_status_ids = []
          batch.each do |client|
            result = process_client(client)
            no_roi_status_ids << client.id if result.nil?
            values << result if result
          end

          GrdaWarehouse::ClientRoiAuthorization.import(
            values,
            on_duplicate_key_update: {
              conflict_target: [:destination_client_id],
              columns: values.first&.keys&.excluding(:destination_client_id),
            },
          )

          # Cleanup auth records for clients that have lost ROI status (but client still exists)
          GrdaWarehouse::ClientRoiAuthorization.where(destination_client: no_roi_status_ids).delete_all
          # Clears stale consent_form_id and related fields on the client record. This is a no-op
          # for clients that never had consent, but necessary for those whose ROI was removed.
          GrdaWarehouse::Hud::Client.bulk_invalidate_consent!(no_roi_status_ids, batch_size: batch_size) if no_roi_status_ids.any?
        end

        # Invalidate consent for clients whose ROI has expired but still have consent_form_id set
        expired_scope = GrdaWarehouse::ClientRoiAuthorization.
          where(status: [GrdaWarehouse::ClientRoiAuthorization::PARTIAL_STATUS, GrdaWarehouse::ClientRoiAuthorization::FULL_STATUS]).
          where.not(expires_at: nil).
          where(expires_at: ..Date.current).
          joins(:destination_client).
          merge(GrdaWarehouse::Hud::Client.where.not(consent_form_id: nil))
        expired_scope = expired_scope.where(destination_client_id: client_ids) if client_ids
        expired_client_ids = expired_scope.pluck(:destination_client_id)
        GrdaWarehouse::Hud::Client.bulk_invalidate_consent!(expired_client_ids, batch_size: batch_size)

        # cleanup orphaned auth records where the client record no-longer exists at all
        orphan_ids = GrdaWarehouse::ClientRoiAuthorization.with_invalid_client.pluck(:id)
        orphan_ids.each_slice(batch_size) do |ids|
          GrdaWarehouse::ClientRoiAuthorization.where(id: ids).delete_all
        end
      end
      did_run
    end

    protected

    # @return [ActiveRecord::Relation<GrdaWarehouse::Hud::Client>] destination clients only
    def destination_client_scope
      GrdaWarehouse::Hud::Client.destination
    end

    # Build a hash of ROI authorization attributes for a destination client.
    # @param destination_client [GrdaWarehouse::Hud::Client] a destination client
    # @return [Hash, nil] authorization attributes for upsert, or nil if the client has no current ROI status
    def process_client(destination_client)
      status = roi_status(destination_client)

      return nil unless status

      {
        status: status,
        destination_client_id: destination_client.id,
        coc_codes: roi_coc_codes(destination_client),
        starts_at: destination_client.consent_form_signed_on,
        expires_at: roi_expiry_date(destination_client),
      }
    end

    # Calculate the ROI expiration date for a client based on the configured release duration.
    # Raises if the duration is time-based and the client has no signature date.
    # @param client [GrdaWarehouse::Hud::Client]
    # @return [Date, nil] expiration date, or nil for indefinite releases
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

    # @return [String] configured release duration (e.g. 'One Year', 'Two Years', 'Use Expiration Date', 'Indefinite')
    def roi_duration
      GrdaWarehouse::Hud::Client.release_duration
    end

    # @param client [GrdaWarehouse::Hud::Client]
    # @return [Array<String>, nil] sorted unique CoC codes the client has consented to, or nil if none
    def roi_coc_codes(client)
      result = client.consented_coc_codes&.compact_blank&.presence
      result&.sort&.uniq
    end

    # Determine the ROI authorization status for a client.
    # Returns nil when no authorization record should be created or kept. This happens when:
    #   - the signature date is missing and the duration mode requires one to compute validity, or
    #   - the client has no active, partial, or revoked consent of any kind.
    # @param client [GrdaWarehouse::Hud::Client]
    # @return [String, nil] one of the ClientRoiAuthorization status constants, or nil
    def roi_status(client)
      return nil if client.consent_form_signed_on.nil? && roi_duration.in?(['One Year', 'Two Years'])

      if client.revoked_consent?
        GrdaWarehouse::ClientRoiAuthorization::REVOKED_STATUS
      elsif client.partial_release?
        GrdaWarehouse::ClientRoiAuthorization::PARTIAL_STATUS
      elsif client.release_valid?
        GrdaWarehouse::ClientRoiAuthorization::FULL_STATUS
      end
    end

    # Acquire an advisory lock so only one instance of this task runs at a time.
    # Skips execution (does not yield) if the lock is already held.
    def with_lock(&block)
      lock_name = self.class.name.demodulize
      GrdaWarehouseBase.with_advisory_lock(lock_name, timeout_seconds: 0, &block)
    end
  end
end
