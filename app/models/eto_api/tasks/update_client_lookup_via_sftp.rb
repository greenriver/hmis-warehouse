###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'net/sftp'
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
  class UpdateClientLookupViaSftp < UpdateClientLookup
    include TsqlImport
    attr_accessor :logger

    # Fetch client mapping from Gmail and replace all records for each data source with
    # new values
    def run!
      return unless GrdaWarehouse::Config.get(:eto_api_available)

      self.logger = Rails.logger
      logger.info 'Fetching client mappings from ETO'
      @config = YAML.load(ERB.new(File.read(Rails.root.join('config', 'hmis_sftp.yml'))).result)[Rails.env] # rubocop:disable Security/YAMLLoad
      @data_sources = GrdaWarehouse::DataSource.importable_via_s3.where(short_name: @config.keys).select do |ds|
        @config[ds.short_name]['api_match_file'].present?
      end
      logger.info "Looking at #{@data_sources.count} data sources"
      @data_sources.each do |ds|
        @attachment = nil
        logger.info "Fetching client mapping for data source: #{ds.short_name}, ..."
        @attachment = fetch_most_recent_mapping_file(ds)
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

    protected def fetch_most_recent_mapping_file(data_source)
      connection_info = @config[data_source.short_name]
      return unless connection_info['api_match_file'].present?

      sftp = Net::SFTP.start(
        connection_info['host'],
        connection_info['username'],
        password: connection_info['password'],
        # verbose: :debug,
        auth_methods: ['publickey', 'password'],
      )
      file_path = connection_info['api_match_file']
      sftp.download!(file_path)
    end
  end
end
