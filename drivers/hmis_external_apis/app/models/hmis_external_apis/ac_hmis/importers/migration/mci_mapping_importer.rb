###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis::Importers::Migration
  class MciMappingImporter
    attr_accessor :io, :new_record_count, :existing_record_count, :clobber

    def initialize(io:, clobber: false)
      self.io = io
      self.new_record_count = 0
      self.existing_record_count = 0
      self.clobber = clobber
    end

    def run!
      make_lookup_table!

      # Delete all MCI IDs
      mci_id_scope.delete_all if clobber

      # Iterate through MCI Unique IDs that (1) we have, and (2) are present in the file.
      # For each MCI Unique ID, create mapped MCI ID(s) (unless they already exist).
      mci_unique_ids.find_each do |mci_unique_id|
        lookup[mci_unique_id.value].each do |mci_id|
          mapped = get_matching_mci_id(client_id: mci_unique_id.source_id, mci_id: mci_id)
          mapped.remote_credential ||= remote_credential

          self.new_record_count += 1 if mapped.new_record?
          self.existing_record_count += 1 if mapped.persisted?

          mapped.save!
        end
      end

      Rails.logger.info "#{self.new_record_count} MCI ID records were added. #{self.existing_record_count} MCI ID records already existed."
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

    def get_matching_mci_id(client_id:, mci_id:)
      mci_id_scope
        .where(source_id: client_id)
        .where(value: mci_id)
        .first_or_initialize
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
