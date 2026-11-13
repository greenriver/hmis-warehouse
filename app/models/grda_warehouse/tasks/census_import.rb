###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::Tasks
  class CensusImport
    def initialize replace_all = nil
      @replace_all = true if replace_all.present?
    end

    def run!
      Rails.logger.info 'Processing GrdaWarehouse::Census census format'

      Rails.logger.info 'Replacing all GrdaWarehouse::Census census records' if @replace_all

      return unless GrdaWarehouse::ServiceHistoryEnrollment.exists?

      # Determine the appropriate date range
      if @replace_all
        # never build back beyond 2010
        start_date = [GrdaWarehouse::ServiceHistoryEnrollment.minimum(:first_date_in_program), '2010-01-01'.to_date].max
        end_date = Date.current
      else
        end_date = Date.current
        start_date = end_date - 3.years
      end
      GrdaWarehouse::Census::CensusBuilder.call(start_date, end_date)
    end
  end
end
