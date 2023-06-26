###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis
  class ImportProjectsJob < ApplicationJob
    include NotifierConfig

    def perform
      setup_notifier('HMIS Projects')

      if Importers::S3ZipFilesImporter.run_mper?
        Importers::S3ZipFilesImporter.mper
      else
        Rails.logger.info 'Not running MPER importer due to lack of credentials'
      end
    rescue StandardError => e
      @notifier.ping('Failure in project importer job', { exception: e })
      Rails.logger.fatal e.message
    end
  end
end
