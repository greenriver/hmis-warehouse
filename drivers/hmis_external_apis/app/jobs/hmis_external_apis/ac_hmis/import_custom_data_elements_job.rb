###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis
  class ImportCustomDataElementsJob < ApplicationJob
    include NotifierConfig

    def perform
      setup_notifier('HMIS Projects')
      Importers::S3ZipFilesImporter.custom_data_elements
    rescue StandardError => e
      @notifier.ping('Failure in project importer job', { exception: e })
      Rails.logger.fatal e.message
    end
  end
end
