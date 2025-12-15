###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# See docs/features/hmis_client_merges.md

module Hmis
  class MergeClientsJob < BaseJob
    attr_accessor :clients
    attr_accessor :client_to_retain
    attr_accessor :clients_needing_reference_updates
    attr_accessor :actor
    attr_accessor :data_source_id
    attr_accessor :merge_audit

    def perform(client_ids:, actor_id:)
      raise 'You cannot merge less than two clients' if Array.wrap(client_ids).length < 2

      self.actor = User.find(actor_id)
      self.clients = Hmis::Hud::Client.
        preload(:names, :contact_points, :addresses, :custom_data_elements).
        find(client_ids).
        map do |client|
          # set some defaults
          client.DateCreated ||= 10.years.ago.to_date
          client.DateUpdated ||= 10.years.ago.to_date
          client
        end.
        sort_by { |client| [client.DateCreated.to_datetime, client.id] }

      self.client_to_retain = clients[0]
      self.clients_needing_reference_updates = clients[1..]
      self.data_source_id = \
        clients.map(&:data_source_id).uniq.tap do |data_sources|
          raise 'We should only have one data source!' unless data_sources.length == 1
        end.first

      Rails.logger.info "Merging #{clients.length} clients by #{actor.name}. (Client IDs: #{client_ids.join(', ')})"

      Hmis::Hud::Client.transaction do
        save_audit_trail
        update_oldest_client_with_merged_attributes
        merge_and_find_primary_name
        merge_custom_data_elements
        update_client_id_foreign_keys
        delete_warehouse_clients
        update_personal_id_foreign_keys
        merge_mci_ids
        merge_mci_unique_ids
        merge_scan_cards
        merge_client_locations
        # TODO(#8241) - merge CE records such as referrals, and possibly candidacy events?

        client_to_retain.reload
        dedup(client_to_retain.names, keepers: dedup(client_to_retain.names.where(primary: true)))
        dedup(client_to_retain.contact_points)
        dedup(client_to_retain.addresses)
        dedup(client_to_retain.custom_data_elements)
        client_to_retain.reload
        destroy_merged_clients
        mark_clients_as_dirty_after_merge
      end
    end

    private

    # This merge job stores a pre_merge_mappings hash in the merge audit record, mapping
    # record ids to the values of the foreign key field that they pointed to before the merge.
    # {
    #   enrollments: {}, # [id => { 'PersonalID' => value }]
    #   names: {}, # [id => { 'PersonalID' => value }]
    #   addresses: {}, # [id => { 'PersonalID' => value }]
    #   contact_points: {}, # [id => { 'PersonalID' => value }]
    #   custom_data_elements: {}, # [id => { 'owner_id' => value }]
    #   files: {}, # [id => { 'client_id' => value }]
    #   mci_ids: {}, # [id => { 'source_id' => value }]
    #   mci_unique_ids: {}, # [id => { 'source_id' => value }]
    #   scan_cards: {}, # [id => { 'client_id' => value }]
    #   client_locations: {}, # [id => { 'client_id' => value }]
    #   source_clients: {}, # [client_id => { 'destination_id' => value }]
    # }
    def build_and_update_merge_mappings(key:, scope:, attributes:)
      mapping = {}
      scope.each do |record|
        mapping[record.id] = record.slice(attributes)
      end
      update_merge_mappings(key, mapping) if mapping.any?
    end

    def update_merge_mappings(key, mappings)
      key_str = key.to_s
      current_mappings = merge_audit.pre_merge_mappings || {}
      current_mappings[key_str] = (current_mappings[key_str] || {}).merge(mappings.stringify_keys)
      merge_audit.update_column(:pre_merge_mappings, current_mappings)
    end

    def save_audit_trail
      Rails.logger.info 'Saving audit trail with initial state'
      # Create merge audit trail, storing the attributes for each client at time of merge
      self.merge_audit = Hmis::ClientMergeAudit.create!(
        actor_id: actor.id,
        merged_at: Time.current,
        pre_merge_state: clients.map(&:attributes),
        pre_merge_mappings: {},
      )

      retained_client_id = client_to_retain.id
      deleted_client_ids = clients_needing_reference_updates.map(&:id)

      # For any deleted clients, update any of their merge histories to point to the new retained client
      Hmis::ClientMergeHistory.where(retained_client_id: deleted_client_ids).update_all(retained_client_id: retained_client_id)

      # Create a new history record for each client that was deleted
      history_records = deleted_client_ids.map do |deleted_client_id|
        {
          retained_client_id: retained_client_id,
          deleted_client_id: deleted_client_id,
          client_merge_audit_id: merge_audit.id,
        }
      end
      Hmis::ClientMergeHistory.import!(history_records)
    end

    def update_oldest_client_with_merged_attributes
      Rails.logger.info 'Choosing the best attributes from the collection of clients'

      merged_attributes = ::GrdaWarehouse::Tasks::ClientCleanup.new.choose_attributes_from_sources(client_to_retain.attributes, clients)

      Rails.logger.info "Saving merged values to client #{client_to_retain.id}"

      client_to_retain.attributes = merged_attributes
      client_to_retain.save!(validate: false)
    end

    def merge_and_find_primary_name
      Rails.logger.info 'Merging names and finding primary one'

      # Create CustomClientNames for any Clients who lack a CustomClientName matching the name fields on the client record.
      # (Either they don't have any CustomClientName records, or the records have gotten out-of-sync)
      unpersisted_name_records = clients.map do |client|
        next if client.names.any? { |name| names_match?(client, name) }

        name = client.build_custom_client_name_from_client_record
        name.CustomClientNameID = Hmis::Hud::Base.generate_uuid
        name
      end.compact

      # Dedup and save the new name records
      deduped_names = dedup_unpersisted(unpersisted_name_records)
      Hmis::Hud::CustomClientName.import!(deduped_names, validate: false, timestamps: true) if deduped_names.any?

      name_ids = clients.flat_map { |client| client.names.map(&:id) }
      name_scope = Hmis::Hud::CustomClientName.where(id: name_ids)

      # Capture pre-merge name mappings
      build_and_update_merge_mappings(
        key: 'names',
        # Only capture mappings for names that we will update
        # (not names that are already associated with the retained client)
        scope: name_scope.where.not(personal_id: client_to_retain.personal_id),
        attributes: 'PersonalID',
      )

      # Update all names to point to client_to_retain
      primary_found = false
      name_scope.sort_by(&:id).each do |name|
        # consider this name "primary" if it matches the name on the client_to_retain's Client record,
        # which was already set to the chosen "best" name by update_oldest_client_with_merged_attributes
        primary = names_match?(client_to_retain, name) && !primary_found

        name.client = client_to_retain
        name.primary = primary ? true : false
        name.save!(validate: false)

        primary_found = true if name.primary
      end

      raise "Unexpected, we should have found a primary name for #{client_to_retain.id}" unless primary_found
    end

    private def names_match?(client, name)
      [client.first_name, client.middle_name, client.last_name, client.name_suffix] == [name.first, name.middle, name.last, name.suffix]
    end

    def merge_custom_data_elements
      Rails.logger.info 'Merging custom data elements'

      element_ids = clients.flat_map(&:custom_data_elements).map(&:id)

      # Capture pre-merge CDE mappings before updating
      cde_scope = Hmis::Hud::CustomDataElement.where(id: element_ids).where.not(owner_id: client_to_retain.id)
      build_and_update_merge_mappings(key: 'custom_data_elements', scope: cde_scope, attributes: 'owner_id')
      cde_scope.update_all(owner_id: client_to_retain.id)

      Rails.logger.info 'uniqify custom data elements for each definition'

      working_set = Hmis::Hud::CustomDataElement.
        where(id: element_ids).
        preload(:data_element_definition).
        to_a.
        group_by(&:data_element_definition)

      working_set.each do |definition, elements|
        next if definition.repeats
        next if elements.length == 1

        values = elements.sort_by(&:DateUpdated)

        # Destroy duplicate CDEs. Some may have been in pre_merge_mappings, which is fine and will help us restore them later if unmerge is needed.
        # Any manual or automated restoration process should account for the fact that CDEDs may have been deleted and need to be recreated, not just moved.
        values[0..-2].each(&:destroy!)
      end
    end

    def dedup(records, keepers: [])
      keepers = keepers.to_a
      records = records.to_a.sort_by(&:id) # fixup db dependent ordering
      records -= keepers # don't check records we know we want to keep
      records.each do |record|
        kept = keepers.detect { |u| u.equal_for_merge?(record) }
        if kept
          Rails.logger.info "Removing #{record} which is a duplicate of #{kept}"
          record.destroy!
        else
          keepers.push(record)
        end
      end
      keepers
    end

    def dedup_unpersisted(unpersisted_records)
      keepers = []
      unpersisted_records.each do |record|
        next if keepers.detect { |u| u.equal_for_merge?(record) }

        keepers.push(record)
      end
      keepers
    end

    def update_client_id_foreign_keys
      candidates = [
        [Hmis::File, 'files'],
      ]

      Rails.logger.info "Updating #{candidates.length} tables with foreign keys to merged clients (client_id)"
      client_ids = clients_needing_reference_updates.map(&:id)

      candidates.each do |candidate, mapping_key|
        candidate_scope = candidate.where(client_id: client_ids)
        build_and_update_merge_mappings(key: mapping_key, scope: candidate_scope, attributes: 'client_id')
        candidate_scope.update_all(client_id: client_to_retain.id)
      end

      # Update ReferralHouseholdMembers in a way that respects uniqueness constraint on (client_id, referral_id).
      # These aren't stored in pre_merge_mappings because it's legacy functionality.
      HmisExternalApis::AcHmis::ReferralHouseholdMember.where(client_id: client_ids).each do |rhhm|
        # Find retained client's household membership for this referral, if exists
        rhhm_for_retained_client = HmisExternalApis::AcHmis::ReferralHouseholdMember.find_by(
          client_id: client_to_retain.id,
          referral_id: rhhm.referral_id,
        )

        if rhhm_for_retained_client
          # The retained client already has membership on this referral, so just delete the duplicate
          rhhm.destroy!
        else
          # Update the referral household record to point to the retained client
          rhhm.update!(client_id: client_to_retain.id)
        end
      end
    end

    def merge_mci_ids
      mci_ids = HmisExternalApis::AcHmis::Mci.external_ids
      current_ids_for_retained_client = mci_ids.where(source: client_to_retain).pluck(:value)
      records_by_value = mci_ids.where(source: clients_needing_reference_updates).
        where.not(value: current_ids_for_retained_client).
        order(:id).reverse.index_by(&:value) # de-duplicate by value, take first id

      # Capture pre-merge MCI ID mappings before updating
      mci_scope = mci_ids.where(id: records_by_value.values.map(&:id))
      build_and_update_merge_mappings(key: 'mci_ids', scope: mci_scope, attributes: 'source_id')
      mci_scope.each do |external_id|
        # save individually to trigger paper trail version creation
        external_id.update!(source_id: client_to_retain.id)
      end
    end

    # Note: WarehouseChangesJob process kicks off MergeClientsJob for clients that
    # share the same MCI Unique ID, so that is the most likely scenario. However,
    # it's also possible to perform a manual merge in HMIS for two clients that
    # may or may not share MCI Unique ID values.
    def merge_mci_unique_ids
      # If retained client has an MCI Unique ID, no action is needed.
      # Max 1 MCI Unique ID is permitted per client, so if any of
      # the merged clients have differing MCI Unique IDs, they will be destroyed.
      # (This could happen in the case of a manual merge).
      return if client_to_retain.ac_hmis_mci_unique_id.present?

      # If retained client does not have an MCI Unique ID, try to find one to keep from the merged clients
      mci_unique_id_to_keep = HmisExternalApis::ExternalId.mci_unique_ids.
        where(source: clients_needing_reference_updates).
        max_by(&:updated_at)
      return unless mci_unique_id_to_keep

      # Capture pre-merge MCI Unique ID mapping before updating
      build_and_update_merge_mappings(key: 'mci_unique_ids', scope: [mci_unique_id_to_keep], attributes: 'source_id')

      # Re-assign this MCI Unique ID to the retained client
      mci_unique_id_to_keep.update!(source: client_to_retain)
    end

    def merge_scan_cards
      # Update all Scan Cards for deleted clients to point to the retained client, including deactivated scan cards
      client_ids = clients_needing_reference_updates.map(&:id)
      scan_card_scope = Hmis::ScanCardCode.with_deleted.where(client_id: client_ids)

      # Capture pre-merge scan card mappings before updating
      build_and_update_merge_mappings(key: 'scan_cards', scope: scan_card_scope, attributes: 'client_id')

      scan_card_scope.update_all(client_id: client_to_retain.id)
    end

    def merge_client_locations
      # Update all Client Locations for deleted clients to point to the retained client
      # Note: for locations collected in HMIS these are probably also tied to an Enrollment via `source_id`, but the client_id
      # reference is necessary to maintain for the warehouse reports
      client_ids = clients_needing_reference_updates.map(&:id)
      location_scope = ::ClientLocationHistory::Location.where(client_id: client_ids)

      # Capture pre-merge client location mappings before updating
      build_and_update_merge_mappings(key: 'client_locations', scope: location_scope, attributes: 'client_id')

      location_scope.update_all(client_id: client_to_retain.id)
    end

    def delete_warehouse_clients
      Rails.logger.info 'Deleting warehouse clients of merged clients'

      # Capture warehouse destination_id mappings before deleting
      warehouse_clients = ::GrdaWarehouse::WarehouseClient.
        where(source_id: clients_needing_reference_updates.map(&:id))

      # don't use build_and_update_merge_mappings here, since we need to key by record.source_id
      mappings = {}
      warehouse_clients.find_each do |wc|
        mappings[wc.source_id] = { 'destination_id' => wc.destination_id }
      end
      update_merge_mappings('source_clients', mappings) if mappings.any?

      warehouse_clients.find_each(&:destroy!)
    end

    def update_personal_id_foreign_keys
      candidates = [
        Hmis::Hud::Assessment,
        Hmis::Hud::AssessmentQuestion,
        Hmis::Hud::AssessmentResult,
        Hmis::Hud::CurrentLivingSituation,
        Hmis::Hud::CustomAssessment,
        Hmis::Hud::CustomCaseNote,
        Hmis::Hud::CustomClientAddress,
        Hmis::Hud::CustomClientContactPoint,
        # Hmis::Hud::CustomClientName,      # Handled in separate method
        Hmis::Hud::CustomService,
        Hmis::Hud::Disability,
        Hmis::Hud::EmploymentEducation,
        Hmis::Hud::Enrollment,
        Hmis::Hud::Event,
        Hmis::Hud::Exit,
        Hmis::Hud::HealthAndDv,
        Hmis::Hud::IncomeBenefit,
        Hmis::Hud::Service,
        Hmis::Hud::YouthEducationStatus,
      ]

      Rails.logger.info "Updating #{candidates.length} tables with foreign keys to merged clients (PersonalID and data source)"

      personal_ids = clients_needing_reference_updates.map(&:personal_id)

      candidates.each do |candidate|
        t = candidate.arel_table

        candidate_scope = candidate.
          where(t['PersonalID'].in(personal_ids)).
          where(t['data_source_id'].eq(data_source_id))

        next unless candidate_scope.exists?

        # Capture mappings for enrollments, addresses, and contact_points.
        # Enrollment-related records (assessments, services, disabilities, etc.) are tied to enrollments
        # via EnrollmentID, so we don't need separate mappings for them.
        case candidate.name
        when 'Hmis::Hud::Enrollment'
          build_and_update_merge_mappings(key: 'enrollments', scope: candidate_scope, attributes: 'PersonalID')
        when 'Hmis::Hud::CustomClientAddress'
          build_and_update_merge_mappings(key: 'addresses', scope: candidate_scope, attributes: 'PersonalID')
        when 'Hmis::Hud::CustomClientContactPoint'
          build_and_update_merge_mappings(key: 'contact_points', scope: candidate_scope, attributes: 'PersonalID')
        end

        candidate_scope.update_all(PersonalID: client_to_retain.personal_id)
      end
    end

    def destroy_merged_clients
      Rails.logger.info 'soft-deleting merged clients'
      ids = clients_needing_reference_updates.map(&:id)

      # Temporarily skip the mark_destination_client_dirty callback to avoid excessive queries during bulk destroy
      Hmis::Hud::Client.skip_callback(:destroy, :after, :mark_destination_client_dirty)

      begin
        scope = Hmis::Hud::Client.where(id: ids)
        # preload associations to reduce n+1 when destroying a batch
        preloads = Hmis::Hud::Client.reflect_on_all_associations.
          filter { |a| a.options[:dependent] == :destroy }.
          map(&:name)
        scope.preload(*preloads).each(&:destroy!)
      ensure
        # Restore the callback
        Hmis::Hud::Client.set_callback(:destroy, :after, :mark_destination_client_dirty)
      end
    end

    def mark_clients_as_dirty_after_merge
      return unless Hmis::Ce.configuration.enabled?

      # Find destination client for the retained client
      destination_client_id = client_to_retain.destination_client&.id
      return unless destination_client_id

      # Mark the destination client as dirty
      Hmis::Ce::ChangeMarker.upsert_or_bump_version('GrdaWarehouse::Hud::Client', trackable_ids: [destination_client_id])
      Rails.logger.info "Marked destination client #{destination_client_id} as dirty after merge for retained client #{client_to_retain.id}"
    end
  end
end
