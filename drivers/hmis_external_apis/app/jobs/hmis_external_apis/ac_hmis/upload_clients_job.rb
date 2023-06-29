###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis
  class UploadClientsJob < ApplicationJob
    include NotifierConfig

    attr_accessor :state

    def perform
      setup_notifier('HMIS Upload Clients')

      if Exporters::ClientExportUploader.can_run?
        export = Exporters::ClientExport.new
        export.run!

        uploader = Exporters::ClientExportUploader.new(
          io_streams: [
            OpenStruct.new(
              name: 'Client.csv',
              io: export.output,
            ),
          ],
        )

        uploader.run!
        self.state = :success
      else
        self.state = :not_run
        Rails.logger.info 'Not running client upload due to lack of credentials'
      end
    rescue StandardError => e
      puts e.message
      self.state = :failed
      @notifier.ping('Failure in upload clients job', { exception: e })
      Rails.logger.fatal e.message
    end
  end
end
