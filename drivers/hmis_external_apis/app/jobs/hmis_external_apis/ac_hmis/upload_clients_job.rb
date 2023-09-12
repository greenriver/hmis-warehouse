###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# job = HmisExternalApis::AcHmis::UploadClientsJob.new
module HmisExternalApis::AcHmis
  class UploadClientsJob < BaseJob
    include NotifierConfig

    attr_accessor :state

    def perform(mode = 'clients_with_mci_ids_and_address')
      setup_notifier("AC Data Warehouse upload (mode: #{mode})")
      if Exporters::ClientExportUploader.can_run?
        Rails.logger.info "Running #{mode} upload clients job"
        case mode
        when 'clients_with_mci_ids_and_address' then clients_with_mci_ids_and_address
        when 'hmis_csv_export' then hmis_csv_export
        when 'project_crosswalk' then project_crosswalk
        else
          raise "invalid item to upload: #{mode}"
        end
        self.state = :success
      else
        self.state = :not_run
        Rails.logger.info "Not running #{mode} due to lack of credentials"
      end
    rescue StandardError => e
      puts e.message
      self.state = :failed
      @notifier.ping('Failure in upload clients job', { exception: e })
      Rails.logger.fatal e.message
    end

    private

    def clients_with_mci_ids_and_address
      export = Exporters::ClientExport.new
      export.run!

      uploader = Exporters::ClientExportUploader.new(
        filename_format: '%Y-%m-%d-clients.zip',
        io_streams: [
          OpenStruct.new(
            name: 'Client.csv',
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

      uploader = Exporters::ClientExportUploader.new(
        filename_format: "%Y-%m-%d-HMIS-#{hash}-hudcsv.zip",
        pre_zipped_data: export.content,
      )

      uploader.run!
    end

    def project_crosswalk
      export = HmisExternalApis::AcHmis::Exporters::ProjectsCrossWalkFetcher.new
      export.run!

      uploader = Exporters::ClientExportUploader.new(
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
  end
end
