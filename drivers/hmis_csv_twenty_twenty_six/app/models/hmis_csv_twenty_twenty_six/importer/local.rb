###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# This is a copy of Importers::HmisAutoMigrate::Local for use during the transition to
# FY2026.  Once we're running auto-migrate with FY2026, this should be removed.
require 'aws-sdk-rails'
require 'zip'
module HmisCsvTwentyTwentySix::Importer
  class Local < Importers::HmisAutoMigrate::Local
    attr_accessor :importer

    def initialize(
      data_source_id:,
      deidentified: false,
      allowed_projects: false,
      file_path: 'tmp/hmis_import',
      project_cleanup: true
    )
      TodoOrDie('Remove this class', by: '2025-10-01')
      setup_notifier('HMIS Local FY2026 Importer')
      @data_source_id = data_source_id
      @deidentified = deidentified
      @allowed_projects = allowed_projects
      @file_path = file_path
      @local_path = File.join(file_path, @data_source_id.to_s, Time.current.to_i.to_s)
      @project_cleanup = project_cleanup
    end

    private def upload_zip_class
      HmisCsvTwentyTwentySix::Importer::UploadedZip
    end

    private def loader_class
      ::HmisCsvTwentyTwentySix::Loader::Loader
    end
  end
end
