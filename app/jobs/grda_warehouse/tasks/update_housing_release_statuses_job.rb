###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  module Tasks
    class UpdateHousingReleaseStatusesJob < ApplicationJob
      queue_as :default

      def perform
        Rails.logger.info 'Starting background update of housing release statuses'
        service = GrdaWarehouse::Tasks::UpdateHousingReleaseStatuses.new
        service.run!
        Rails.logger.info 'Housing release status update completed'
      end
    end
  end
end
