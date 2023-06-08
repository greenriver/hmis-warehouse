###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis::Importers
  class ProjectsImporter
    include NotifierConfig

    attr_accessor :attempt
    attr_accessor :dir

    def initialize(dir:, key:, etag:)
      self.dir = dir
      self.attempt = ProjectsImportAttempt.where(etag: etag, key: key).first_or_initialize
    end

    def run!
      start
      validate
    end

    def start
      setup_notifier('HMIS Projects')
      Rails.logger.info "Starting #{attempt.key}"
      attempt.attempted_at = Time.now
      attempt.status = 'started'
      attempt.save!
    end

    def validate
      Rails.logger.info 'Validating CSVs'
    end
  end
end
