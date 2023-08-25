###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis::Importers
  class ProjectsImportAttempt < GrdaWarehouseBase
    self.table_name = :ac_hmis_projects_import_attempts

    FAILED    = 'failed'.freeze
    IGNORED   = 'ignored'.freeze
    STARTED   = 'started'.freeze
    SUCCEEDED = 'succeeded'.freeze

    validates :key, uniqueness: { scope: [:etag], case_sensitive: false }

    scope :given, ->(s3_object) { where(etag: s3_object.etag, key: s3_object.key) }
    scope :to_skip, -> { where(status: [IGNORED, FAILED, SUCCEEDED]) }
  end
end
