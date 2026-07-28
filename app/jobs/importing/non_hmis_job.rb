###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Importing
  class NonHmisJob < BaseJob
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    def initialize(upload:, data_source_id:)
      @upload = upload
      @data_source_id = data_source_id
    end

    def perform
      # The importers hand the file off to Roo, which needs something on disk, so
      # stream the attachment to a tempfile that goes away when we're done.
      with_local_file do |file|
        GrdaWarehouse::Config.active_supplemental_enrollment_importer_class.run!(@data_source_id, file, @upload.id)
      end
    end

    # ActiveStorage downloads the blob to a tempfile for us; legacy records that
    # still hold their bytes in the database need one built by hand.
    private def with_local_file(&block)
      return @upload.upload_file.open(&block) if @upload.upload_file.attached?

      Tempfile.create(['non_hmis_upload', File.extname(@upload.read_attribute(:file).to_s)], binmode: true) do |file|
        file.write(@upload.file_data)
        file.rewind
        block.call(file)
      end
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
