###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis::Importers::Migration
  class MciMappingImporter
    attr_accessor :io, :new_record_count

    def initialize(io:)
      self.io = io
      self.new_record_count = 0
    end

    def run!
      make_lookup_table!

      mci_unique_ids.find_each do |mci_unique_id|
        mapped = get_matching_mci_id(client_id: mci_unique_id.source_id, mci_id: lookup[mci_unique_id.value])

        log_what_happened(client_id: mci_unique_id.source_id, mapped: mapped)

        mapped.remote_credential ||= remote_credential

        self.new_record_count += 1 if mapped.new_record?

        mapped.save!
      end

      Rails.logger.info "#{self.new_record_count} records were added."
    end

    private

    def make_lookup_table!
      lookup
    end

    def mci_unique_ids
      result = HmisExternalApis::ExternalId
        .for_clients
        .where(namespace: HmisExternalApis::AcHmis::WarehouseChangesJob::NAMESPACE)
        .where(value: lookup.keys)

      Rails.logger.warn("We could not find any matching MCI unique IDs. That doesn't seem right") if result.none?

      result
    end

    def get_matching_mci_id(client_id:, mci_id:)
      HmisExternalApis::ExternalId
        .for_clients
        .where(namespace: HmisExternalApis::AcHmis::Mci::SYSTEM_ID)
        .where(source_id: client_id)
        .where(value: mci_id)
        .first_or_initialize
    end

    def log_what_happened(client_id:, mapped:)
      state = mapped.persisted? ? 'existed' : 'was new'

      changed_words =
        if mapped.new_record?
          ''
        elsif mapped.value_changed?
          ' Its value changed'
        else
          ''
        end

      Rails.logger.info "Found mapping for client ID #{client_id}, and it #{state}.#{changed_words}"
    end

    def lookup
      return @lookup unless @lookup.nil?

      @lookup = {}

      require 'roo-xls'

      sheet = ::Roo::Excel.new(io)
      parsed = sheet.parse(headers: true)

      parsed.each do |row|
        mci_id = row['MCI_ID']&.to_i&.to_s

        @lookup[row['MCI_UNIQ_ID']&.to_i&.to_s] = mci_id if mci_id.present?
      end

      # Feels a little safer than adding .drop(1) to the parsed array
      @lookup.delete(0)
      @lookup.delete('0')
      @lookup.delete(nil)

      raise "There was a problem with your spreadsheeet. It didn't have enough rows" if @lookup.keys.length < 2

      @lookup
    end

    def remote_credential
      # Which one? Neither?
      GrdaWarehouse::RemoteCredential.where(slug: ['ac_hmis_mci', 'ac_hmis_mci_unique_id']).first
    end
  end
end
