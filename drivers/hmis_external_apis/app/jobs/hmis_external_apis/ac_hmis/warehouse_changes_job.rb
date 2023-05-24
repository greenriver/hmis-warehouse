###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis
  class WarehouseChangesJob < ApplicationJob
    include ArelHelper

    attr_accessor :since, :records_needing_processing, :clients, :external_ids, :merge_sets, :actor_id

    NAMESPACE = 'ac_hmis_mci_unique_id'.freeze

    def perform(since: Time.now - 3.days, actor_id:)
      self.since = since
      self.records_needing_processing = []
      self.actor_id = actor_id

      collect_records_to_inspect
      fetch_clients
      fetch_mci_unique_ids
      upsert_changes
      merge_clients_by_mci_unique_id
    end

    private

    # It's more efficent to get all the records we're interested in before
    # hitting the database to avoid excessive queries.
    def collect_records_to_inspect
      Rails.logger.info 'Collection records to inspect'

      count = 0
      each_record_we_are_interested_in do |record|
        count += 1
        records_needing_processing << record
      end

      Rails.logger.info "Considering #{count} records"
    end

    def fetch_clients
      Rails.logger.info 'Fetching client records'

      personal_ids = records_needing_processing.map { |r| r['clientId'] }

      self.clients = Hmis::Hud::Client
        .where(c_t[:PersonalID].in(personal_ids))
        .where(c_t[:data_source_id].eq(data_source.id))
    end

    def fetch_mci_unique_ids
      Rails.logger.info 'Fetching MCI unique IDS and making a lookup table'

      e_t = HmisExternalApis::ExternalId.arel_table

      # by client_id
      self.external_ids = HmisExternalApis::ExternalId
        .where(e_t[:source_type].eq('Hmis::Hud::Client'))
        .where(e_t[:source_id].in(clients.map(&:id)))
        .where(namespace: NAMESPACE)
        .to_a
        .map { |eid| [eid.source_id, eid] }
        .to_h
    end

    def upsert_changes
      Rails.logger.info 'Upserting discovered changes'

      insert_count = 0
      update_count = 0
      no_change_count = 0

      client_by_personal_id = clients
        .map { |c| [c.personal_id, c] }
        .to_h

      records_needing_processing.each do |record|
        client = client_by_personal_id[record['clientId']]
        external_id = external_ids[client.id]

        if external_id.blank?
          insert_count += 1
          HmisExternalApis::ExternalId.create!(
            value: record['mciUniqId'],
            source: client,
            namespace: NAMESPACE,
            remote_credential: data_warehouse_api.send(:creds),
          )
        elsif external_id.value != record['mciUniqId']
          update_count += 1
          external_id.update_attribute(:value, record['mciUniqId'])
        else
          no_change_count += 1
        end
      end

      Rails.logger.info "Inserted #{insert_count} MCI unique IDs"
      Rails.logger.info "Updated #{update_count} MCI unique IDs"
      Rails.logger.info "Ignored #{no_change_count} MCI unique IDs"
    end

    def merge_clients_by_mci_unique_id
      e_t = HmisExternalApis::ExternalId.arel_table

      self.merge_sets = HmisExternalApis::ExternalId
        .where(e_t[:source_type].eq('Hmis::Hud::Client'))
        .where(namespace: NAMESPACE)
        .group(:value)
        .having('count(*) > 1')
        .select('value, array_agg(source_id ORDER BY source_id) AS client_ids')

      Rails.logger.info "Found #{merge_sets.length} duplicate MCI unique IDs"

      Rails.logger.info 'Enqueuing dedup jobs for each one'

      merge_sets.each do |set|
        Hmis::MergeClientsJob.perform_later(client_ids: set.client_ids, actor_id: actor_id)
      end
    end

    def data_source
      # FIXME: Is this right?
      @data_source ||= GrdaWarehouse::DataSource.authoritative.where(name: 'HMIS').first!
    end

    def each_record_we_are_interested_in
      data_warehosue_api.each_change do |record|
        record['last_modified_date_time'] = Time.zone.parse(record['lastModifiedDate'])
        record['mci_unique_id_date_time'] = Time.zone.parse(record['mciUniqIdDate'])

        if record['last_modified_date_time'] < since
          Rails.logger.info "Got to the end of the changes we're interested in. Finishing up"
          break
        end

        # From Gig: I think we can just filter out any records where
        # mciUniqIdDate is not within our requested 3-day period. Aka if it's
        # only included in the response because of demographic changes, throw
        # it out.
        if record['mci_unique_id_date_time'] < since
          Rails.logger.info "Skipping a record that changed for a reason we don't care about"
          next
        end

        yield record
      end
    end

    def data_warehouse_api
      @data_warehouse_api ||= DataWarehouseApi.new
    end
  end
end
