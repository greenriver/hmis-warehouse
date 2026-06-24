###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Manual/support tool to undo a single HMIS client merge performed by MergeClientsJob.
# May later be exposed in the UI.
#
# Usage:
#   Hmis::UndoMergeClientsJob.perform_now(retained_client_id:, deleted_client_id:, dry_run: false)
#
# Limitations:
# - Only undoes one deleted client from a specific merge; chain merges require the current
#   retained_client_id from ClientMergeHistory.
# - Does not revert attribute changes on the retained client (it may have been edited post-merge).
# - Does not recreate records destroyed during merge dedup (names, contact points, addresses, CDEs).
# - Does not restore legacy ReferralHouseholdMember rows
# - Does not manually restore WarehouseClient links; warehouse_identify_duplicate_clients (queued below)
#   re-establishes destination client assignments.
# - Destroys the ClientMergeHistory row on success so clients no longer appear linked in search;
#   the ClientMergeAudit is retained for audit purposes.
module Hmis
  class UndoMergeClientsJob < BaseJob
    CLIENT_ID_FOREIGN_KEY_CANDIDATES = [
      [Hmis::File, 'files'],
      [Hmis::ScanCardCode, 'scan_cards', { with_deleted: true, restore_if_deleted: true }],
      [::ClientLocationHistory::Location, 'client_locations'],
      [Hmis::Ce::Referral, 'ce_referrals'],
    ].freeze

    PERSONAL_ID_FOREIGN_KEY_CANDIDATES = [
      [Hmis::Hud::CustomClientName, 'names'],
      [Hmis::Hud::CustomClientAddress, 'addresses'],
      [Hmis::Hud::CustomClientContactPoint, 'contact_points'],
    ].freeze

    attr_accessor :retained_client, :deleted_client, :merge_audit, :merge_history, :dry_run

    def perform(retained_client_id:, deleted_client_id:, dry_run: false)
      self.dry_run = dry_run
      self.retained_client = Hmis::Hud::Client.find(retained_client_id)
      self.deleted_client = Hmis::Hud::Client.with_deleted.find(deleted_client_id)
      self.merge_history = Hmis::ClientMergeHistory.find_by(retained_client_id: retained_client_id, deleted_client_id: deleted_client_id)
      self.merge_audit = merge_history&.client_merge_audit

      validate!

      Rails.logger.info "Undoing merge#{' (dry run)' if dry_run}: Restoring client #{deleted_client_id} from merge with client #{retained_client_id}"

      # Store ID for the destination client of the retained client, for post-processing cleanup
      destination_id = retained_client.destination_client&.id

      Hmis::Hud::Client.transaction do
        restore_deleted_client
        restore_enrollments
        restore_associated_records
        destroy_merge_history
      end

      return if dry_run

      # Ensures that deleted service history enrollments get removed from the retained client destination
      ::GrdaWarehouse::Tasks::SanityCheckServiceHistory.new(client_ids: [destination_id]).run!

      # If CE is enabled, mark the destination client as dirty for reprocessing
      Hmis::Ce::ChangeMarker.upsert_or_bump_version('GrdaWarehouse::Hud::Client', trackable_ids: [destination_id]) if Hmis::Ce.configuration.enabled?

      # Run identify-duplicates to re-establish destination links
      ::GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!

      # Queue service history processing
      ::GrdaWarehouse::Tasks::ServiceHistory::Enrollment.queue_batch_process_unprocessed!
    end

    private

    # Ensure required clients, merge history, and audit data are present before undoing.
    def validate!
      raise ArgumentError, 'Retained client must be provided' unless retained_client
      raise ArgumentError, 'Deleted client must be provided' unless deleted_client
      raise ArgumentError, 'Clients have not been merged' unless merge_history
      raise ArgumentError, 'Merge audit is missing' unless merge_audit
      raise ArgumentError, 'Deleted client is not soft-deleted' unless deleted_client.deleted?
      raise ArgumentError, 'Pre-merge mappings are missing' unless merge_audit.pre_merge_mappings.present?
    end

    # Clear DateDeleted on the merged-away client so it is active again.
    def restore_deleted_client
      Rails.logger.info "Restoring deleted client #{deleted_client.id}"
      return if dry_run

      deleted_client.update_column(:DateDeleted, nil)
      deleted_client.reload
    end

    # Move enrollments and enrollment-related PersonalID references back to the restored client.
    def restore_enrollments
      enrollment_mappings = merge_audit.mappings_for('enrollments')
      return if enrollment_mappings.empty?

      Rails.logger.info "Restoring #{enrollment_mappings.size} enrollments to client #{deleted_client.id}"

      updated_enrollment_ids = []
      enrollment_mappings.each do |enrollment_id, mapping_data|
        enrollment = Hmis::Hud::Enrollment.find_by(id: enrollment_id)
        original_personal_id = mapping_data['PersonalID'] || mapping_data['personal_id']

        next unless enrollment
        next unless enrollment.personal_id == retained_client.personal_id
        next unless original_personal_id == deleted_client.personal_id

        apply_or_log_update(record: enrollment, column: :PersonalID, value: deleted_client.personal_id, label: "enrollment #{enrollment_id}")
        updated_enrollment_ids << enrollment.id
      end

      return if updated_enrollment_ids.empty?

      updated_enrollment_scope = Hmis::Hud::Enrollment.where(id: updated_enrollment_ids)
      HmisDataCleanup::Util.fix_incorrect_personal_id_references!(
        enrollment_scope: updated_enrollment_scope,
        dry_run: dry_run,
      )

      updated_enrollment_scope.each(&:invalidate_processing!) unless dry_run
    end

    # Restore all non-enrollment records tracked in pre_merge_mappings.
    def restore_associated_records
      # Restore records whose foreign key is PersonalID (names, addresses, contact points).
      PERSONAL_ID_FOREIGN_KEY_CANDIDATES.each do |model, mapping_key|
        restore_personal_id_mappings(model: model, mapping_key: mapping_key)
      end

      # Restore records whose foreign key is client_id (files, scan cards, locations, CE referrals).
      CLIENT_ID_FOREIGN_KEY_CANDIDATES.each do |model, mapping_key, options = {}|
        restore_client_id_mappings(model: model, mapping_key: mapping_key, **options)
      end

      # Restore Client-owned custom data elements moved to the retained client during merge.
      restore_custom_data_elements

      # Restore MCI external IDs moved to the retained client during merge.
      restore_mci_ids

      # Restore MCI Unique ID moved to the retained client during merge.
      restore_mci_unique_ids
    end

    # Shared helper: restore PersonalID-based records from audit mappings.
    def restore_personal_id_mappings(model:, mapping_key:)
      mappings = merge_audit.mappings_for(mapping_key)
      return if mappings.empty?

      mappings.each do |record_id, mapping_data|
        record = model.find_by(id: record_id)
        original_personal_id = mapping_data['PersonalID'] || mapping_data['personal_id']

        next unless record
        next unless record.PersonalID == retained_client.personal_id
        next unless original_personal_id == deleted_client.personal_id

        apply_or_log_update(record: record, column: :PersonalID, value: deleted_client.personal_id, label: "#{model.name} #{record_id}")
      end
    end

    # Shared helper: restore client_id-based records from audit mappings.
    def restore_client_id_mappings(model:, mapping_key:, with_deleted: false, restore_if_deleted: false)
      mappings = merge_audit.mappings_for(mapping_key)
      return if mappings.empty?

      scope = with_deleted ? model.with_deleted : model
      mappings.each do |record_id, mapping_data|
        record = scope.find_by(id: record_id)
        original_client_id = mapping_data['client_id']&.to_i

        next unless record
        next unless record.client_id == retained_client.id
        next unless original_client_id == deleted_client.id

        apply_or_log_update(record: record, column: :client_id, value: deleted_client.id, label: "#{model.name} #{record_id}")
        record.restore if restore_if_deleted && !dry_run && record.respond_to?(:deleted?) && record.deleted?
      end
    end

    def restore_custom_data_elements
      mappings = merge_audit.mappings_for('custom_data_elements')
      return if mappings.empty?

      mappings.each do |cde_id, mapping_data|
        cde = Hmis::Hud::CustomDataElement.find_by(id: cde_id)
        original_owner_id = mapping_data['owner_id']

        next unless cde
        next unless cde.owner_id == retained_client.id
        next unless original_owner_id == deleted_client.id

        apply_or_log_update(record: cde, column: :owner_id, value: deleted_client.id, label: "custom data element #{cde_id}")
      end
    end

    def restore_mci_ids
      mappings = merge_audit.mappings_for('mci_ids')
      return if mappings.empty?

      mappings.each do |external_id, mapping_data|
        external_id_record = HmisExternalApis::AcHmis::Mci.external_ids.find_by(id: external_id)
        original_source_id = mapping_data['source_id']

        next unless external_id_record
        next unless external_id_record.source_id == retained_client.id
        next unless original_source_id == deleted_client.id

        apply_or_log_update(record: external_id_record, column: :source_id, value: deleted_client.id, label: "MCI ID #{external_id}")
      end
    end

    def restore_mci_unique_ids
      mappings = merge_audit.mappings_for('mci_unique_ids')
      return if mappings.empty?

      mappings.each do |external_id, mapping_data|
        external_id_record = HmisExternalApis::ExternalId.mci_unique_ids.find_by(id: external_id)
        original_source_id = mapping_data['source_id']

        next unless external_id_record
        next unless external_id_record.source_id == retained_client.id
        next unless original_source_id == deleted_client.id

        apply_or_log_update(record: external_id_record, column: :source_id, value: deleted_client.id, label: "MCI Unique ID #{external_id}")
      end
    end

    # Apply a column update or log what would change in dry-run mode.
    def apply_or_log_update(record:, column:, value:, label:)
      Rails.logger.info "Restored #{label} to client #{deleted_client.id}"
      return if dry_run

      record.update_column(column, value)
    end

    # Remove merge history so clients no longer appear linked in search; audit remains on ClientMergeAudit.
    def destroy_merge_history
      Rails.logger.info "Destroying merge history #{merge_history.id}"
      return if dry_run

      merge_history.destroy!
    end
  end
end
