###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'gmail'
require 'csv'
# Fix for bug in imap date conversion
# https://github.com/gmailgem/gmail/issues/228
class Object
  def to_imap_date
    date = respond_to?(:utc) ? utc.to_s : to_s
    Date.parse(date).strftime('%d-%b-%Y')
  end
end

module EtoApi::Tasks
  class UpdateClientLookup
    include TsqlImport
    attr_accessor :logger

    def initialize
      # map data source to subject line
      @data_sources = [[1, '[Client GUID Table DND]'], [3, '[Client GUID Table BPHC]']]
      @expected_headers = ['CLID', 'ClientGUID', 'SiteID', 'Site', 'MaxAuditDate']
      @headers = [:site_id_in_data_source, :warehouse_id, :id_in_data_source, :last_contact, :data_source_id, :client_id]
    end

    # Fetch client mapping from Gmail and replace all records for each data source with
    # new values
    def run!
      raise 'Implement in sub class'
    end

    protected def fetch_most_recent_mapping_file(_ds_id, _subject)
      raise 'Implement in sub class'
    end

    protected def parse_csv_from_file(data)
      @csv = CSV.parse(data, headers: true, return_headers: false)
      unless @csv.first.headers == @expected_headers
        logger.warn 'CSV file does not appear valid, found:'
        logger.warn @csv.first.headers.inspect
        logger.warn 'expected:'
        logger.warn @expected_headers.inspect
        return nil
      end
      @csv
    end

    def translate_csv_for_warehouse(ds_id)
      @csv.map do |row|
        next unless row.length == @expected_headers.length

        next unless row['ClientGUID'].present?

        # remove the nasty {} that shouldn't be there, but somehow sneak back in
        row['ClientGUID'] = row['ClientGUID'].gsub('{', '').gsub('}', '').upcase

        # attempt to find the client associated with this id for future joining
        client_id = client_id_from_personal_id(row['ClientGUID'].gsub('-', ''))
        [
          row['SiteID'],
          row['ClientGUID'],
          row['CLID'],
          row['MaxAuditDate'],
          ds_id,
          client_id,
        ]
      end.compact
    end

    # Very basically validate the structure
    # Pull off the Site name (first column)
    # Add the data source id and client_id at the end
    # Delete any entries for the current data source
    # Stream new file into the warehouse
    protected def update_client_lookup(ds_id)
      return unless @csv.present?

      @csv = translate_csv_for_warehouse(ds_id)
      GrdaWarehouse::ApiClientDataSourceId.transaction do
        GrdaWarehouse::ApiClientDataSourceId.where(data_source_id: ds_id).delete_all
        insert_batch(GrdaWarehouse::ApiClientDataSourceId, @headers, @csv, transaction: false)
      end
      @csv.size
    end

    protected def clean_hmis_clients
      GrdaWarehouse::HmisClient.
        where.not(
          client_id: GrdaWarehouse::ApiClientDataSourceId.
            where.not(client_id: nil).
            select(:client_id).distinct,
        ).delete_all
    end

    protected def clean_hmis_forms
      GrdaWarehouse::HmisForm.
        where.not(
          client_id: GrdaWarehouse::ApiClientDataSourceId.
            where.not(client_id: nil).
            select(:client_id).distinct,
        ).delete_all
    end

    protected def client_source
      GrdaWarehouse::Hud::Client.source
    end

    protected def client_id_from_personal_id(personal_id)
      @client_ids ||= client_source.pluck(:PersonalID, :id).map do |p_id, id|
        [p_id.upcase, id]
      end.to_h
      @client_ids[personal_id.upcase]
    end
  end
end
