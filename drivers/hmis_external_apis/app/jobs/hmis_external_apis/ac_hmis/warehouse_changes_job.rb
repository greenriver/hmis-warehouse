###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis
  class WarehouseChangesJob < BaseJob
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)
    include NotifierConfig
    include ArelHelper

    attr_accessor :since, :records_needing_processing, :clients, :external_ids, :merge_sets, :actor_id

    NAMESPACE = 'ac_hmis_mci_unique_id'.freeze

    def perform(since: Time.now - 3.days, actor_id:)
      return unless HmisExternalApis::AcHmis::DataWarehouseApi.enabled?

      self.since = since
      self.records_needing_processing = []
      self.actor_id = actor_id

      setup_notifier('Fetch changes from AC Data Warehouse')

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
      Rails.logger.info 'Collecting records to inspect'

      count = 0
      each_record_we_are_interested_in do |record|
        count += 1
        records_needing_processing << record
      end

      Rails.logger.info "Considering #{count} records"
    end

    def fetch_clients
      Rails.logger.info 'Fetching client records'

      destination_ids = records_needing_processing.map { |r| r['clientId'] }

      self.clients = Hmis::Hud::Client.where(data_source: data_source).
        joins(:warehouse_client_source).
        preload(:warehouse_client_source).
        where(GrdaWarehouse::WarehouseClient.arel_table[:destination_id].in(destination_ids))
    end

    def fetch_mci_unique_ids
      Rails.logger.info 'Fetching MCI unique IDS and making a lookup table'

      e_t = HmisExternalApis::ExternalId.arel_table

      # by client_id
      self.external_ids = HmisExternalApis::ExternalId.
        where(e_t[:source_type].eq('Hmis::Hud::Client')).
        where(e_t[:source_id].in(clients.map(&:id))).
        where(namespace: NAMESPACE).
        to_a.
        map { |eid| [eid.source_id, eid] }.
        to_h
    end

    def upsert_changes
      Rails.logger.info 'Upserting discovered changes'

      insert_count = 0
      update_count = 0
      no_change_count = 0
      unrecognized_destination_id_count = 0

      # HMIS Source Clients, keyed by Destination ID
      clients_by_destination_id = clients.group_by(&:warehouse_id).stringify_keys

      records_needing_processing.each do |record|
        # Find source clients for this destination id
        clients = clients_by_destination_id[record['clientId']]
        if clients.nil?
          unrecognized_destination_id_count += 1
          next
        end

        # Iterate through each source client. If there are multiple source clients, they will
        # get the same MCI Unique ID and be merged in the merge step.
        clients.each do |client|
          external_id = external_ids[client.id] # mci unique id

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
      end

      debug_msg "Inserted #{insert_count} MCI unique IDs"
      debug_msg "Updated #{update_count} MCI unique IDs"
      debug_msg "Ignored #{no_change_count} MCI unique IDs"
      debug_msg "Skipped #{unrecognized_destination_id_count} unrecognized Client IDs in response"
    end

    def merge_clients_by_mci_unique_id
      self.merge_sets = HmisExternalApis::ExternalId.
        joins(:client). # join to ensure we're not pulling in any ExternalIds for deleted clients
        where(namespace: NAMESPACE).
        group(:value).
        having('count(*) > 1').
        select('value, array_agg(source_id ORDER BY source_id) AS client_ids')

      debug_msg "Found #{merge_sets.length} duplicate MCI unique IDs"

      debug_msg 'Enqueuing dedup jobs for each one'

      merge_sets.each do |set|
        Hmis::MergeClientsJob.perform_later(client_ids: set.client_ids, actor_id: actor_id)
      end
    end

    def data_source
      @data_source ||= HmisExternalApis::AcHmis.data_source
    end

    def each_record_we_are_interested_in
      data_warehouse_api.each_change do |record|
        record['last_modified_date_time'] = Time.zone.parse(record['lastModifiedDate'])
        record['mci_unique_id_date_time'] = Time.zone.parse(record['mciUniqIdDate'])

        if record['last_modified_date_time'] < since
          debug_msg "Got to the end of the changes we're interested in. Finishing up"
          break
        end

        # We can filter out any records where mciUniqIdDate is not within our requested 3-day period.
        # Aka if it's only included in the response because of demographic changes, throw it out.
        next if record['mci_unique_id_date_time'] < since

        yield record
      end
    end

    def debug_msg(str)
      @notifier.ping(str)
    end

    def data_warehouse_api
      @data_warehouse_api ||= DataWarehouseApi.new
    end
  end
end
