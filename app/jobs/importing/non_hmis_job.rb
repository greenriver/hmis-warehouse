###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Importing
  class NonHmisJob < BaseJob
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    def initialize(upload:, data_source_id:)
      @upload = upload
      @data_source_id = data_source_id
    end

    def perform
      base_path = 'var/non_hmis_import'
      path = "#{base_path}/#{@upload.id}"
      FileUtils.mkdir_p(base_path) unless File.directory?(base_path)
      file = File.open(path, 'w+b')
      file.write(@upload.content)
      task = GrdaWarehouse::Tasks::EnrollmentExtrasImport.new(
        source: file,
        data_source_id: @data_source_id,
      )
      task.run!
    end

    def enqueue(job)
    end

    def success(_job)
      @upload.update(percent_complete: 100, completed_at: Time.current)
    end

    def max_attempts
      1
    end
  end
end
