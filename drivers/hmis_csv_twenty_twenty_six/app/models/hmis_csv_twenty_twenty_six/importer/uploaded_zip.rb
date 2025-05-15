###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# This is a copy of Importers::HmisAutoMigrate::UploadedZip for use during the transition to
# FY2026.  Once we're running auto-migrate with FY2026, this should be removed.
require 'zip'
require 'pty'
require 'expect'
module HmisCsvTwentyTwentySix::Importer
  class UploadedZip < Importers::HmisAutoMigrate::UploadedZip
    def initialize(
      upload_id:,
      data_source_id:,
      deidentified: false,
      allowed_projects: false,
      file_path: 'tmp/hmis_import',
      file_password: nil,
      project_cleanup: true
    )
      TodoOrDie('Remove this class', by: '2025-10-01')
      setup_notifier('HMIS Upload FY2026 Importer')
      @data_source_id = data_source_id
      @upload = GrdaWarehouse::Upload.find(upload_id.to_i)
      @deidentified = deidentified
      @allowed_projects = allowed_projects
      @file_path = file_path
      @local_path = Dir.mktmpdir([file_path, @data_source_id.to_s])
      @file_password = file_password
      @project_cleanup = project_cleanup
      @post_processor = if @allowed_projects
        ->(_) { replace_original_upload_file }
      else
        -> {}
      end
    end

    private def loader_class
      HmisCsvTwentyTwentySix::Loader::Loader
    end
  end
end
