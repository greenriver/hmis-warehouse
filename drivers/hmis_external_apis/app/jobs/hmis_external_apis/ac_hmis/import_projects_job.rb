###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisExternalApis::AcHmis
  class ImportProjectsJob < BaseJob
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    def perform
      if Importers::S3ZipFilesImporter.run_mper?
        Importers::S3ZipFilesImporter.mper
      else
        Rails.logger.info 'Not running MPER importer due to lack of credentials'
      end
    rescue StandardError => e
      Sentry.capture_exception(e)
      Rails.logger.fatal("#{e.message} #{e.backtrace.join("\n")}")
    end
  end
end
