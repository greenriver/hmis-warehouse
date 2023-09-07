###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# job =  HmisExternalApis::AcHmis::UploadClientsJob.new
module HmisExternalApis::AcHmis
  class UploadClientsJob < BaseJob
    include NotifierConfig

    attr_accessor :state

    def perform(mode = 'clients_with_mci_ids_and_address')
      setup_notifier('HMIS Upload Clients')
      if Exporters::ClientExportUploader.can_run?
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

      # FIXME: Not sure what this should be a hash of. I'll refactor to take content
      # into account in a later step if that's needed. Could be a hash of the
      # current time or content or sorted list of unique ids in the file. Or,
      # maybe something else.
      hash = SecureRandom.hex(8)

      uploader = Exporters::ClientExportUploader.new(
        filename_format: "%Y-%m-%d-HMIS-#{hash}-hudcsv.zip",
        # FIXME: I believe this content is a string of zipped content, but I haven't confirmed that.
        pre_zipped_data: export.content,
      )

      uploader.run!
    end

    def project_crosswalk
      # Use these for reference:
      # app/views/warehouse_reports/hmis_cross_walks/index.xlsx.axlsx
      # app/controllers/warehouse_reports/hmis_cross_walks_controller.rb

      # From elliot to flesh out:
      @filter = ::Filters::FilterBase.new(user_id: User.system_user.id, enforce_one_year_range: false)
      @filter.update(
        start: 10.years.ago.to_date,
        end: Date.current,
        data_source_ids: [HmisExternalApis::AcHmis.data_source.id],
      )

      # FIXME: Then you'll need to render the index.xlsx action in WarehouseReports::HmisCrossWalksController to get the file.

      # Can be similar to HmisExternalApis::AcHmis::Exporters::ClientExport

      # FIXME: stubs for now
      orgs = OpenStruct.new(output:     StringIO.new('Warehouse ID,HMIS Organization ID,Organization Name,Data Source,Date Updated'))
      projects = OpenStruct.new(output: StringIO.new('Warehouse ID,HMIS ProjectID,Project Name,HMIS Organization ID,Organization Name,Data Source,Date Updated'))

      uploader = Exporters::ClientExportUploader.new(
        filename_format: '%Y-%m-%d-cross-walks.zip',
        io_streams: [
          OpenStruct.new(
            name: 'Organizations-cross-walk.csv',
            io: orgs.output,
          ),
          OpenStruct.new(
            name: 'Project-cross-walk.csv',
            io: projects.output,
          ),
        ],
      )

      uploader.run!
    end
  end
end
