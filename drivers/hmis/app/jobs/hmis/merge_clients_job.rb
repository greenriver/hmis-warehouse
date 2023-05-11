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

    def perform(client_ids:, actor_id:)
      raise 'You cannot merge less than two clients' if Array.wrap(client_ids).length < 2

      self.actor = User.find(actor_id)
      self.clients = Hmis::Hud::Client.preload(:names, :contact_points, :addresses).order(Hmis::Hud::Client.arel_table['DateCreated']).find(client_ids)
      self.client_to_retain = clients[0]
      self.clients_needing_reference_updates = clients[1..]

      Rails.logger.info "Merging #{clients.length} clients by #{actor.name}"

      Hmis::Hud::Client.transaction do
        save_audit_trail
        update_oldest_client_with_merged_attributes
        dedup_and_merge_names_addresses_and_contact_points
        update_foreign_keys
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

    # FIXME: If this is too n+1, I can refactor into database updates
    # FIXME: This doesn't dedup anything yet.
    def dedup_and_merge_names_addresses_and_contact_points
      Rails.logger.info 'Merging names'
      Hmis::Hud::CustomClientName.where(id: clients.flat_map(&:names).map(&:id)).update_all(primary: nil)
      clients.flat_map(&:names).each do |name|
        primary = [client_to_retain.first_name, client_to_retain.middle_name, client_to_retain.last_name, client_to_retain.name_suffix] == [name.first, name.middle, name.last, name.suffix]

        name.client = client_to_retain
        name.primary = primary ? true : nil
        name.save!(validate: false)
      end

      Rails.logger.info 'Merging addresses'
      clients.flat_map(&:addresses).each do |address|
        address.update_attribute(:client, client_to_retain)
      end

      Rails.logger.info 'Merging contact points'
      clients.flat_map(&:contact_points).each do |contact_point|
        contact_point.update_attribute(:client, client_to_retain)
      end
    end

    def update_foreign_keys
      Rails.logger.info 'Updating foreign keys to merged clients'
    end

    def destroy_merged_clients
      Rails.logger.info 'soft-deleting merged clients'
      clients_needing_reference_updates.map(&:destroy)
    end
  end
end
