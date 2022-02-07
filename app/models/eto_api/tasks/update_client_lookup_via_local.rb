###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'csv'

module EtoApi::Tasks
  class UpdateClientLookupViaLocal < UpdateClientLookup
    include TsqlImport
    attr_accessor :logger

    def initialize(ds_id:, file_path:)
      @ds_id = ds_id
      @file_path = file_path
      super()
    end

    # Fetch client mapping from Gmail and replace all records for each data source with
    # new values
    def run!
      return unless GrdaWarehouse::Config.get(:eto_api_available)
      return unless File.exist?(@file_path)

      self.logger = Rails.logger
      logger.info 'Fetching client mappings from ETO'
      ds = GrdaWarehouse::DataSource.importable_via_s3.find(@ds_id.to_i)
      @attachment = nil
      logger.info "Fetching client mapping for data source: #{ds.short_name}, ..."
      @attachment = File.read(@file_path)
      if @attachment.present?
        @csv = parse_csv_from_file(@attachment)
        updated_rows = update_client_lookup(ds.id)
        logger.info "Found #{updated_rows} clients to update ..."
        cleaned_clients = clean_hmis_clients
        logger.info "Removed #{cleaned_clients} hmis clients no longer referenced ..."
        cleaned_forms = clean_hmis_forms
        logger.info "Removed #{cleaned_forms} hmis forms attached to clients no longer referenced ..."
      end
      logger.info "...client mapping for Data Source ID: #{ds.short_name} complete"
    end
  end
end
