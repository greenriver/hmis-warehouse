###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis
  class ImportProjectsJob < ApplicationJob
    def perform
      HmisExternalApis::AcHmis::Importers::S3ZipFilesImporter.mper
    end
  end
end
