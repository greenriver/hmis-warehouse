###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Confidence
  class SourceExitsJob < BaseJob
    include ArelHelper

    def initialize(client_ids:)
      @client_ids = client_ids
    end

    def perform
      @client_ids.each do |id|
        GrdaWarehouse::Confidence::SourceExits.calculate_queued_for_client(id)
      end
    end

    def enqueue(job, queue: :low_priority)
    end

    def max_attempts
      2
    end
  end
end
