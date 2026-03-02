###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis
  # intentionally doesn't restore attributes on retained client from pre_merge_state because
  # the retained client may have been updated since the merge, and we don't want to overwrite those changes.
  # FIXME: should delete merge history after so clients don't show up in search together
  class UndoMergeClientsJob < BaseJob
    attr_accessor :retained_client, :deleted_client, :merge_audit, :merge_history

    def perform(retained_client_id:, deleted_client_id:)
      self.retained_client = Hmis::Hud::Client.find(retained_client_id)
      self.deleted_client = Hmis::Hud::Client.with_deleted.find(deleted_client_id)
      self.merge_history = find_merge_history
      self.merge_audit = merge_history&.client_merge_audit

      validate!

      Rails.logger.info "Undoing merge: Restoring client #{deleted_client_id} from merge with client #{retained_client_id}"

      Hmis::Hud::Client.transaction do
        restore_deleted_client
        restore_enrollments
        restore_associated_records
      end
      # queue identify duplicates to run in the background. should we also run match_existing here?
      Hmis::Hud::Client.warehouse_identify_duplicate_clients
      # queue service history processing to reprocess the enrollments
      Hmis::Hud::Enrollment.queue_service_history_processing!
    end

    private

    def validate!
      raise ArgumentError, 'Retained client must be provided' unless retained_client
      raise ArgumentError, 'Deleted client must be provided' unless deleted_client
      raise ArgumentError, 'Clients have not been merged' unless merge_history
      raise ArgumentError, 'Merge audit is missing' unless merge_audit
      raise ArgumentError, 'Deleted client is not soft-deleted' unless deleted_client.deleted?
      raise ArgumentError, 'Pre-merge mappings are missing' unless merge_audit.pre_merge_mappings.present?
    end

    def find_merge_history
      Hmis::ClientMergeHistory.find_by(
        retained_client_id: retained_client.id,
        deleted_client_id: deleted_client.id,
      )
    end

    def restore_deleted_client
      Rails.logger.info "Restoring deleted client #{deleted_client.id}"
      deleted_client.update_column(:DateDeleted, nil)
      deleted_client.reload
    end

    def restore_enrollments
      mappings = merge_audit.pre_merge_mappings || {}
      enrollment_mappings = mappings['enrollments'] || {}

      return if enrollment_mappings.empty?

      Rails.logger.info "Restoring #{enrollment_mappings.size} enrollments to client #{deleted_client.id}"

      updated_enrollment_ids = []
      enrollment_mappings.each do |enrollment_id_str, mapping_data|
        enrollment_id = enrollment_id_str.to_i
        enrollment = Hmis::Hud::Enrollment.find_by(id: enrollment_id)
        original_personal_id = mapping_data['PersonalID'] || mapping_data['personal_id']

        next unless enrollment
        next unless enrollment.personal_id == retained_client.personal_id
        next unless original_personal_id == deleted_client.personal_id

        # update Enrollment to point to deleted client
        enrollment.update_columns(PersonalID: deleted_client.personal_id)
        updated_enrollment_ids << enrollment.id
      end

      # fix PersonalID on other Enrollment-related references (assessments, services, disabilities, etc.)
      updated_enrollment_scope = Hmis::Hud::Enrollment.where(id: updated_enrollment_ids)
      HmisDataCleanup::Util.fix_incorrect_personal_id_references!(enrollment_scope: updated_enrollment_scope, dry_run: false)

      # invalidate processing so service history gets reprocessed (queued later)
      updated_enrollment_scope.each(&:invalidate_processing!)
    end

    def restore_associated_records
      mappings = merge_audit.pre_merge_mappings || {}

      restore_names(mappings['names'])
      restore_addresses(mappings['addresses'])
      restore_contact_points(mappings['contact_points'])
      restore_custom_data_elements(mappings['custom_data_elements'])
      restore_files(mappings['files'])
      restore_mci_ids(mappings['mci_ids'])
      restore_mci_unique_ids(mappings['mci_unique_ids'])
      restore_scan_cards(mappings['scan_cards'])
      restore_client_locations(mappings['client_locations'])
      restore_ce_referrals(mappings['ce_referrals'])

      # Note: Enrollment-related records (assessments, services, disabilities, etc.) are automatically
      # updated when enrollments are transferred via TransferEnrollment, so no need to restore them separately.
    end

    def restore_names(mappings)
      return unless mappings

      mappings.each do |name_id_str, mapping_data|
        name_id = name_id_str.to_i
        name = Hmis::Hud::CustomClientName.find_by(id: name_id)
        original_personal_id = mapping_data['PersonalID'] || mapping_data['personal_id']

        next unless name
        next unless name.PersonalID == retained_client.personal_id
        next unless original_personal_id == deleted_client.personal_id

        name.update_column(:PersonalID, deleted_client.personal_id)
        Rails.logger.info "Restored name #{name_id} to client #{deleted_client.id}"
      end
    end

    def restore_addresses(mappings)
      return unless mappings

      mappings.each do |address_id_str, mapping_data|
        address_id = address_id_str.to_i
        address = Hmis::Hud::CustomClientAddress.find_by(id: address_id)
        original_personal_id = mapping_data['PersonalID'] || mapping_data['personal_id']

        next unless address
        next unless address.PersonalID == retained_client.personal_id
        next unless original_personal_id == deleted_client.personal_id

        address.update_column(:PersonalID, deleted_client.personal_id)
        Rails.logger.info "Restored address #{address_id} to client #{deleted_client.id}"
      end
    end

    def restore_contact_points(mappings)
      return unless mappings

      mappings.each do |contact_point_id_str, mapping_data|
        contact_point_id = contact_point_id_str.to_i
        contact_point = Hmis::Hud::CustomClientContactPoint.find_by(id: contact_point_id)
        original_personal_id = mapping_data['PersonalID'] || mapping_data['personal_id']

        next unless contact_point
        next unless contact_point.PersonalID == retained_client.personal_id
        next unless original_personal_id == deleted_client.personal_id

        contact_point.update_column(:PersonalID, deleted_client.personal_id)
        Rails.logger.info "Restored contact point #{contact_point_id} to client #{deleted_client.id}"
      end
    end

    def restore_custom_data_elements(mappings)
      return unless mappings

      mappings.each do |cde_id_str, mapping_data|
        cde_id = cde_id_str.to_i
        cde = Hmis::Hud::CustomDataElement.find_by(id: cde_id)
        original_owner_id = mapping_data['owner_id']

        # Skip if CDE was destroyed during merge (it won't exist)
        next unless cde

        next unless cde.owner_id == retained_client.id
        next unless original_owner_id == deleted_client.id

        cde.update_column(:owner_id, deleted_client.id)
        Rails.logger.info "Restored custom data element #{cde_id} to client #{deleted_client.id}"
      end
    end

    def restore_files(mappings)
      return unless mappings

      # Restore GrdaWarehouse::ClientFile records
      mappings.each do |file_id_str, mapping_data|
        file_id = file_id_str.to_i
        file = ::GrdaWarehouse::ClientFile.find_by(id: file_id)
        original_client_id = mapping_data['client_id']

        next unless file
        next unless file.client_id == retained_client.id
        next unless original_client_id == deleted_client.id

        file.update_column(:client_id, deleted_client.id)
        Rails.logger.info "Restored file #{file_id} to client #{deleted_client.id}"
      end

      # Restore Hmis::File records
      mappings.each do |file_id_str, mapping_data|
        file_id = file_id_str.to_i
        file = Hmis::File.find_by(id: file_id)
        original_client_id = mapping_data['client_id']

        next unless file
        next unless file.client_id == retained_client.id
        next unless original_client_id == deleted_client.id

        file.update_column(:client_id, deleted_client.id)
        Rails.logger.info "Restored HMIS file #{file_id} to client #{deleted_client.id}"
      end
    end

    def restore_mci_ids(mappings)
      return unless mappings

      mappings.each do |external_id_str, mapping_data|
        external_id = external_id_str.to_i
        external_id_record = HmisExternalApis::AcHmis::Mci.external_ids.find_by(id: external_id)
        original_source_id = mapping_data['source_id']

        next unless external_id_record
        next unless external_id_record.source_id == retained_client.id
        next unless original_source_id == deleted_client.id

        external_id_record.update!(source_id: deleted_client.id)
        Rails.logger.info "Restored MCI ID #{external_id} to client #{deleted_client.id}"
      end
    end

    def restore_mci_unique_ids(mappings)
      return unless mappings

      mappings.each do |external_id_str, mapping_data|
        external_id = external_id_str.to_i
        external_id_record = HmisExternalApis::ExternalId.mci_unique_ids.find_by(id: external_id)
        original_source_id = mapping_data['source_id']

        next unless external_id_record
        next unless external_id_record.source_id == retained_client.id
        next unless original_source_id == deleted_client.id

        external_id_record.update!(source: deleted_client)
        Rails.logger.info "Restored MCI Unique ID #{external_id} to client #{deleted_client.id}"
      end
    end

    def restore_scan_cards(mappings)
      return unless mappings

      mappings.each do |scan_card_id_str, mapping_data|
        scan_card_id = scan_card_id_str.to_i
        scan_card = Hmis::ScanCardCode.with_deleted.find_by(id: scan_card_id)
        original_client_id = mapping_data['client_id']

        next unless scan_card
        next unless scan_card.client_id == retained_client.id
        next unless original_client_id == deleted_client.id

        scan_card.update_column(:client_id, deleted_client.id)
        scan_card.restore if scan_card.deleted?
        Rails.logger.info "Restored scan card #{scan_card_id} to client #{deleted_client.id}"
      end
    end

    def restore_client_locations(mappings)
      return unless mappings

      mappings.each do |location_id_str, mapping_data|
        location_id = location_id_str.to_i
        location = ::ClientLocationHistory::Location.find_by(id: location_id)
        original_client_id = mapping_data['client_id']

        next unless location
        next unless location.client_id == retained_client.id
        next unless original_client_id == deleted_client.id

        location.update_column(:client_id, deleted_client.id)
        Rails.logger.info "Restored client location #{location_id} to client #{deleted_client.id}"
      end
    end

    def restore_ce_referrals(mappings)
      return unless mappings

      mappings.each do |referral_id_str, mapping_data|
        referral_id = referral_id_str.to_i
        referral = Hmis::Ce::Referral.find_by(id: referral_id)
        original_client_id = mapping_data['client_id']

        next unless referral
        next unless referral.client_id == retained_client.id
        next unless original_client_id.to_i == deleted_client.id

        referral.update_column(:client_id, deleted_client.id)
        Rails.logger.info "Restored CE referral #{referral_id} to client #{deleted_client.id}"
      end
    end
  end
end
