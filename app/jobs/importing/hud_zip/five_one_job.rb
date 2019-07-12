###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Importing::HudZip
  class FiveOneJob < BaseJob
    queue_as :low_priority

    def initialize upload_id:, data_source_id:
      @upload_id = upload_id
      @data_source_id = data_source_id
    end

    def perform
      Importers::HMISFiveOne::UploadedZip.new(
        data_source_id: @data_source_id,
        upload_id: @upload_id
      ).import!
    end

    def enqueue(job)
    end

    def max_attempts
      1
    end
  end
end