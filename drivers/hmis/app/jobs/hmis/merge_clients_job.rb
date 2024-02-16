###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis
  class MergeClientsJob < BaseJob
    attr_accessor :clients
    attr_accessor :client_to_retain
    attr_accessor :clients_needing_reference_updates
    attr_accessor :actor
    attr_accessor :data_source_id

    def perform(client_ids:, actor_id:)
      raise 'You cannot merge less than two clients' if Array.wrap(client_ids).length < 2

      self.actor = User.find(actor_id)
      self.clients = Hmis::Hud::Client.
        preload(:names, :contact_points, :addresses).
        find(client_ids).
        map do |client|
          # set some defaults
          client.DateCreated ||= 10.years.ago.to_date
          client.DateUpdated ||= 10.years.ago.to_date
          client
        end.
        sort_by { |client| client.DateCreated.to_datetime }

      self.client_to_retain = clients[0]
      self.clients_needing_reference_updates = clients[1..]
      self.data_source_id = \
        clients.map(&:data_source_id).uniq.tap do |data_sources|
          raise 'We should only have one data source!' unless data_sources.length == 1
        end.first

      Rails.logger.info "Merging #{clients.length} clients by #{actor.name}"

      Hmis::Hud::Client.transaction do
        save_audit_trail
        update_oldest_client_with_merged_attributes
        merge_and_find_primary_name
        merge_custom_data_elements
        update_client_id_foreign_keys
        delete_warehouse_clients
        update_personal_id_foreign_keys
        merge_mci_ids
        merge_scan_cards

        client_to_retain.reload
        dedup(client_to_retain.names, keepers: dedup(client_to_retain.names.where(primary: true)))
        dedup(client_to_retain.contact_points)
        dedup(client_to_retain.addresses)
        dedup(client_to_retain.custom_data_elements)
        client_to_retain.reload
        destroy_merged_clients
      end
    end

    private

    def save_audit_trail
      Rails.logger.info 'Saving audit trail with initial state'
      # Create merge audit trail, storing the attributes for each client at time of merge
      merge_audit = Hmis::ClientMergeAudit.create!(
        actor_id: actor.id,
        merged_at: Time.current,
        pre_merge_state: clients.map(&:attributes),
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

      # Create CustomClientName records for any Clients that don't have them
      unpersisted_name_records = clients.map do |client|
        next unless client.names.empty?

        name = client.build_primary_custom_client_name
        name.CustomClientNameID = Hmis::Hud::Base.generate_uuid
        name.primary = client.id == client_to_retain.id
        name
      end.compact

      # Dedup and save the new name records
      dedup_unpersisted(unpersisted_name_records).map(&:save!)

      name_ids = clients.flat_map { |client| client.names.map(&:id) }
      name_scope = Hmis::Hud::CustomClientName.where(id: name_ids)

      # Update all names to point to client_to_retain
      primary_found = false
      name_scope.sort_by(&:id).each do |name|
        client_val = [client_to_retain.first_name, client_to_retain.middle_name, client_to_retain.last_name, client_to_retain.name_suffix]
        custom_client_name_val = [name.first, name.middle, name.last, name.suffix]
        primary = (client_val == custom_client_name_val) && !primary_found

        name.client = client_to_retain
        name.primary = primary ? true : false
        name.save!(validate: false) # if primary, this save will update the Client name attributes (FirstName, LastName, etc)

        primary_found = true if name.primary
      end
    end

    def merge_custom_data_elements
      Rails.logger.info 'Merging custom data elements'

      element_ids = clients.flat_map(&:custom_data_elements).map(&:id)

      Hmis::Hud::CustomDataElement.where(id: element_ids).update_all(owner_id: client_to_retain.id)

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
        ::GrdaWarehouse::ClientFile,
        Hmis::File,
        Hmis::Wip,
      ]

      Rails.logger.info "Updating #{candidates.length} tables with foreign keys to merged clients (client_id)"
      client_ids = clients_needing_reference_updates.map(&:id)
      candidates.each do |candidate|
        candidate.where(client_id: client_ids).update_all(client_id: client_to_retain.id)
      end

      # Update ReferralHouseholdMembers in a way that respects uniquness constraint on (client_id, referral_id)
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

      mci_ids.where(id: records_by_value.values.map(&:id)).
        update_all(source_id: client_to_retain.id)
    end

    def merge_scan_cards
      # Update all Scan Cards for deleted clients to point to the retained client, including deactivated scan cards
      client_ids = clients_needing_reference_updates.map(&:id)
      Hmis::ScanCardCode.with_deleted.where(client_id: client_ids).update_all(client_id: client_to_retain.id)
    end

    def delete_warehouse_clients
      Rails.logger.info 'Deleting warehouse clients of merged clients'

      ::GrdaWarehouse::WarehouseClient.
        where(source_id: clients_needing_reference_updates.map(&:id)).
        find_each(&:destroy!)
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

      candidates.each do |candidate|
        personal_ids = clients_needing_reference_updates.map(&:personal_id)

        t = candidate.arel_table

        candidate.
          where(t['PersonalID'].in(personal_ids)).
          where(t['data_source_id'].eq(data_source_id)).
          update_all(PersonalID: client_to_retain.personal_id)
      end
    end

    def destroy_merged_clients
      Rails.logger.info 'soft-deleting merged clients'
      clients_needing_reference_updates.map(&:reload).map(&:destroy!)
    end
  end
end
