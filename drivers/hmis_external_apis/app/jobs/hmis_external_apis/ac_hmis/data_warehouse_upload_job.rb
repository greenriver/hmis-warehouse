###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# job = HmisExternalApis::AcHmis::DataWarehouseUploadJob.new
module HmisExternalApis::AcHmis
  class DataWarehouseUploadJob < BaseJob
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)
    include NotifierConfig

    attr_accessor :state

    def perform(methods)
      setup_notifier("AC Data Warehouse upload (methods: #{methods})")
      if Exporters::DataWarehouseUploader.can_run?
        Rails.logger.info "Running #{methods} DW upload job"

        Array.wrap(methods).each do |method|
          if method == 'daily_uploads'
            daily_uploads.each { |m| send(m) } # run all exports in the daily_uploads group
          elsif method == 'quarterly_uploads'
            hmis_csv_export_full_refresh
          elsif known?(method)
            # run one export individually. only used for testing purposes or manual runs.
            send(method)
          else
            raise "unknown method: #{method}" unless known?(method)
          end
        end
        self.state = :success
      else
        self.state = :not_run
        Rails.logger.info "Not running #{methods} due to lack of credentials"
      end
    rescue StandardError => e
      puts e.message
      self.state = :failed
      @notifier.ping('Failure in Data Warehouse uploader job', { exception: e })
      Rails.logger.fatal e.message
    end

    private

    def known?(method)
      known_methods.include?(method)
    end

    def known_methods
      [
        'clients_with_mci_ids_and_address',
        'hmis_csv_export',
        'hmis_csv_export_full_refresh', # runs quarterly
        'project_crosswalk',
        'move_in_address_export',
        'posting_export',
        'custom_fields_export',
        'pathways_export',
      ].freeze
    end

    def daily_uploads
      known_methods - ['hmis_csv_export_full_refresh']
    end

    def clients_with_mci_ids_and_address
      export = Exporters::ClientExport.new
      export.run!

      uploader = Exporters::DataWarehouseUploader.new(
        filename_format: '%Y-%m-%d-clients.zip',
        io_streams: [
          OpenStruct.new(
            name: 'ClientMciMapping.csv',
            io: export.output,
          ),
        ],
      )

      uploader.run!
    end

    def hmis_csv_export
      export = HmisExternalApis::AcHmis::Exporters::HmisExportFetcher.new
      export.run!

      hash = Digest::MD5.hexdigest(export.content)

      uploader = Exporters::DataWarehouseUploader.new(
        filename_format: "%Y-%m-%d-HMIS-#{hash}-hudcsv.zip",
        pre_zipped_data: export.content,
      )

      uploader.run!
    end

    def hmis_csv_export_full_refresh
      export = HmisExternalApis::AcHmis::Exporters::HmisExportFetcher.new
      export.run!(start_date: 10.years.ago.to_date)

      hash = Digest::MD5.hexdigest(export.content)

      uploader = Exporters::DataWarehouseUploader.new(
        filename_format: "%Y-%m-%d-HMIS-full-refresh-#{hash}-hudcsv.zip",
        pre_zipped_data: export.content,
      )

      uploader.run!
    end

    def project_crosswalk
      export = HmisExternalApis::AcHmis::Exporters::ProjectsCrossWalkFetcher.new
      export.run!

      uploader = Exporters::DataWarehouseUploader.new(
        filename_format: '%Y-%m-%d-cross-walks.zip',
        io_streams: [
          OpenStruct.new(
            name: 'Organizations-cross-walk.csv',
            io: export.orgs_csv_stream,
          ),
          OpenStruct.new(
            name: 'Project-cross-walk.csv',
            io: export.projects_csv_stream,
          ),
        ],
      )

      uploader.run!
    end

    def move_in_address_export
      export = HmisExternalApis::AcHmis::Exporters::MoveInAddressExport.new
      export.run!

      uploader = Exporters::DataWarehouseUploader.new(
        filename_format: '%Y-%m-%d-move-in-addresses.zip',
        io_streams: [
          OpenStruct.new(
            name: 'MoveInAddresses.csv',
            io: export.output,
          ),
        ],
      )

      uploader.run!
    end

    def posting_export
      export = HmisExternalApis::AcHmis::Exporters::PostingExport.new
      export.run!

      uploader = Exporters::DataWarehouseUploader.new(
        filename_format: '%Y-%m-%d-postings.zip',
        io_streams: [
          OpenStruct.new(
            name: 'Postings.csv',
            io: export.output,
          ),
        ],
      )

      uploader.run!
    end

    def custom_fields_export
      cded_export = HmisExternalApis::AcHmis::Exporters::CdedExport.new
      cded_export.run!

      cde_export = HmisExternalApis::AcHmis::Exporters::CdeExport.new
      cde_export.run!

      uploader = Exporters::DataWarehouseUploader.new(
        filename_format: '%Y-%m-%d-custom-fields.zip',
        io_streams: [
          OpenStruct.new(
            name: 'CustomFieldDefinitions.csv',
            io: cded_export.output,
          ),
          OpenStruct.new(
            name: 'CustomFieldValues.csv',
            io: cde_export.output,
          ),
        ],
      )

      uploader.run!
    end

    def pathways_export
      export = HmisExternalApis::AcHmis::Exporters::PathwaysExport.new
      export.run!

      uploader = Exporters::DataWarehouseUploader.new(
        filename_format: '%Y-%m-%d-pathways.zip',
        io_streams: [
          OpenStruct.new(
            name: 'Pathways.csv',
            io: export.output,
          ),
        ],
      )

      uploader.run!
    end
  end
end
