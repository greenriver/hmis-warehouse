###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis::Importers::Migration
  class MciMappingImporter
    attr_accessor :io

    def initialize(io:)
      self.io = io
    end

    def run!
      make_lookup_table!

      # Delete all MCI IDs
      num_deleted = mci_id_scope.delete_all.size
      Rails.logger.info "Deleted #{num_deleted} MCI IDs."
      Rails.logger.info "Importing MCI ID mappings for #{lookup.keys.size} MCI Unique IDs."
      # Iterate through MCI Unique IDs that (1) we have, and (2) are present in the file.
      # For each MCI Unique ID, create mapped MCI ID(s).
      new_mci_ids = []
      remote_credential_id = remote_credential.id
      mci_unique_ids.pluck(:value, :source_id).each do |mci_unique_id, source_id|
        lookup[mci_unique_id].each do |mci_id|
          new_mci_ids << {
            namespace: HmisExternalApis::AcHmis::Mci::SYSTEM_ID,
            source_type: 'Hmis::Hud::Client',
            source_id: source_id,
            value: mci_id,
            remote_credential_id: remote_credential_id,
          }
        end
      end

      HmisExternalApis::ExternalId.import!(new_mci_ids)

      Rails.logger.info "#{new_mci_ids.size} MCI IDs were added."
      unmatched_mci_uniq_ids_in_file = lookup.keys - mci_unique_id_scope.pluck(:value)
      Rails.logger.info "#{unmatched_mci_uniq_ids_in_file.size} MCI Unique IDs in the file didn't match any clients on record. #{unmatched_mci_uniq_ids_in_file.take(50)}"
    end

    private

    def make_lookup_table!
      lookup
    end

    def mci_unique_id_scope
      HmisExternalApis::ExternalId
        .for_clients
        .where(namespace: HmisExternalApis::AcHmis::WarehouseChangesJob::NAMESPACE)
    end

    def mci_id_scope
      HmisExternalApis::ExternalId
        .for_clients
        .where(namespace: HmisExternalApis::AcHmis::Mci::SYSTEM_ID)
    end

    def mci_unique_ids
      result = mci_unique_id_scope.where(value: lookup.keys)

      Rails.logger.warn("We could not find any matching MCI unique IDs. That doesn't seem right. You may need to run InitialMciUniqueIdCreationJob.") if result.none?

      result
    end

    # { MCI Unique ID => Array<{ MCI ID }> }
    def lookup
      return @lookup unless @lookup.nil?

      @lookup = {}

      require 'roo-xls'

      sheet = ::Roo::Excel.new(io)
      parsed = sheet.parse(headers: true)

      parsed.each do |row|
        mci_uniq_id = row['MCI_UNIQ_ID']&.to_i&.to_s
        mci_id = row['MCI_ID']&.to_i&.to_s
        next unless mci_uniq_id.present? && mci_id.present?

        @lookup[mci_uniq_id] ||= []
        @lookup[mci_uniq_id] << mci_id if mci_id.present?
      end

      # Feels a little safer than adding .drop(1) to the parsed array
      @lookup.delete(0)
      @lookup.delete('0')
      @lookup.delete(nil)

      raise "There was a problem with your spreadsheeet. It didn't have enough rows" if @lookup.keys.length < 2

      @lookup
    end

    def remote_credential
      GrdaWarehouse::RemoteCredential.active.where(slug: HmisExternalApis::AcHmis::Mci::SYSTEM_ID).first!
    end
  end
end
