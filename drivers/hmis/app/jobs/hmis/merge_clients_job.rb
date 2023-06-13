###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis
  class MergeClientsJob < ApplicationJob
    attr_accessor :clients
    attr_accessor :client_to_retain
    attr_accessor :clients_needing_reference_updates
    attr_accessor :actor
    attr_accessor :data_source_id

    def perform(client_ids:, actor_id:)
      raise 'You cannot merge less than two clients' if Array.wrap(client_ids).length < 2

      self.actor = User.find(actor_id)
      self.clients = Hmis::Hud::Client.preload(:names, :contact_points, :addresses).order(Hmis::Hud::Client.arel_table['DateCreated']).find(client_ids)
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

        client_to_retain.reload
        dedup(:names, keepers: client_to_retain.names.where(primary: true))
        dedup(:contact_points)
        dedup(:addresses)
        dedup(:custom_data_elements)
        destroy_merged_clients
      end
    end

    private

    def save_audit_trail
      Rails.logger.info 'Saving audit trail with initial state'

      Hmis::ClientMergeAudit.create!(
        actor_id: actor.id,
        merged_at: Time.now,
        pre_merge_state: clients.map(&:attributes),
      )
    end

    def update_oldest_client_with_merged_attributes
      Rails.logger.info 'Choosing the best attributes from the collection of clients'

      merged_attributes = GrdaWarehouse::Tasks::ClientCleanup.new.choose_attributes_from_sources(client_to_retain.attributes, clients)

      Rails.logger.info "Saving merged values to client #{client_to_retain.id}"

      client_to_retain.attributes = merged_attributes
      client_to_retain.save!(validate: false)
    end

    def merge_and_find_primary_name
      Rails.logger.info 'Merging names and finding primary one'

      name_ids = clients.flat_map(&:names).map(&:id)
      Hmis::Hud::CustomClientName.where(id: name_ids).update_all(primary: false)

      primary_found = false
      clients.flat_map(&:names).each do |name|
        client_val = [client_to_retain.first_name, client_to_retain.middle_name, client_to_retain.last_name, client_to_retain.name_suffix]
        custom_client_name_val = [name.first, name.middle, name.last, name.suffix]
        primary = (client_val == custom_client_name_val) && !primary_found

        name.client = client_to_retain
        name.primary = primary ? true : false
        name.save!(validate: false)

        primary_found = true if name.primary
      end
    end

    def merge_custom_data_elements
      Rails.logger.info 'Merging custom data elements'

      element_ids = clients.flat_map(&:custom_data_elements).map(&:id)

      Hmis::Hud::CustomDataElement.where(id: element_ids).update_all(owner_id: client_to_retain.id)

      Rails.logger.info 'uniqify custom data elements for each definition'

      working_set = Hmis::Hud::CustomDataElement
        .where(id: element_ids)
        .preload(:data_element_definition)
        .to_a
        .group_by(&:data_element_definition)

      working_set.each do |definition, elements|
        next if definition.repeats
        next if elements.length == 1

        values = elements.sort_by(&:DateUpdated)

        values[0..-2].each(&:destroy)
      end
    end

    def dedup(relation, keepers: [])
      pairs = client_to_retain.send(relation).to_a.combination(2)

      pairs.each do |pair|
        equivalent = if pair[0].respond_to?(:equal_for_merge?)
          pair[0].equal_for_merge?(pair[1])
        else
          pair[0] == pair[1]
        end

        next unless equivalent
        next if pair[1].in?(keepers)

        Rails.logger.info "Removing #{pair[1]} which is a duplicate"
        pair[1].destroy
        client_to_retain.reload
        dedup(relation)
        break
      end
    end

    def update_client_id_foreign_keys
      candidates = [
        GrdaWarehouse::ClientFile,
        Hmis::File,
        Hmis::Wip,
      ]

      Rails.logger.info "Updating #{candidates.length} tables with foreign keys to merged clients (client_id)"

      candidates.each do |candidate|
        client_ids = clients_needing_reference_updates.map(&:id)

        candidate.where(client_id: client_ids).update_all(client_id: client_to_retain.id)
      end
    end

    def merge_mci_ids
      mci_ids = HmisExternalApis::AcHmis::Mci.external_ids
      # merge ids
      records_by_value = mci_ids.where(source: clients_needing_reference_updates)
        .order(:id).reverse.index_by(&:value) # de-duplicate by value, take first id

      mci_ids.where(id: records_by_value.values.map(&:id))
        .update_all(source_id: client_to_retain.id)
    end

    def delete_warehouse_clients
      Rails.logger.info 'Deleting warehouse clients of merged clients'

      # Very unsure I caught the desired behavior correctly here:
      GrdaWarehouse::WarehouseClient
        .where(source_id: clients_needing_reference_updates.map(&:id))
        .destroy_all
    end

    def update_personal_id_foreign_keys
      candidates = [
        Hmis::Hud::Assessment,
        Hmis::Hud::AssessmentQuestion,
        Hmis::Hud::AssessmentResult,
        Hmis::Hud::CurrentLivingSituation,
        Hmis::Hud::CustomClientAddress,
        Hmis::Hud::CustomClientContactPoint,
        # Hmis::Hud::CustomClientName,      # Handled in separate method
        Hmis::Hud::Disability,
        Hmis::Hud::EmploymentEducation,
        Hmis::Hud::Enrollment,
        Hmis::Hud::EnrollmentCoc,
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

        candidate
          .where(t['PersonalID'].in(personal_ids))
          .where(t['data_source_id'].eq(data_source_id))
          .update_all(PersonalID: client_to_retain.personal_id)
      end
    end

    def destroy_merged_clients
      Rails.logger.info 'soft-deleting merged clients'
      clients_needing_reference_updates.map(&:destroy)
    end
  end
end
