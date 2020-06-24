###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Importing::HudZip
  class SixOneOneJob < BaseJob
    queue_as :long_running

    def initialize(upload_id:, data_source_id:, deidentified: false, project_whitelist: false)
      @upload_id = upload_id
      @data_source_id = data_source_id
      @deidentified = deidentified
      @project_whitelist = project_whitelist
    end

    def perform
      importer = Importers::HMISSixOneOne::UploadedZip.new(
        data_source_id: @data_source_id,
        upload_id: @upload_id,
        deidentified: @deidentified,
        project_whitelist: @project_whitelist,
      )
      # Confirm this is not a 2020 file
      if importer.next_version?
        # Queue the next version of the importer
        Delayed::Job.enqueue Importing::HudZip::HmisTwentyTwentyJob.new(
          data_source_id: @data_source_id,
          upload_id: @upload_id,
          deidentified: @deidentified,
          project_whitelist: @project_whitelist,
        ), queue: :long_running
        # Cleanup un-finished import
        importer.remove_import!
      else
        importer.pre_process! if @project_whitelist
        importer.import!
      end
    end

    def enqueue(job)
    end

    def max_attempts
      1
    end
  end
end
