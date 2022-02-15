###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Tasks
  class CensusImport
    include TsqlImport
    include ArelHelper

    def initialize replace_all = nil
      if replace_all.present?
        @replace_all = true
      end
    end

    def run!
      Rails.logger.info 'Processing GrdaWarehouse::Census census format'

      if @replace_all
        Rails.logger.info 'Replacing all GrdaWarehouse::Census census records'
      end

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
      GrdaWarehouse::Census::CensusBuilder.new.create_census(start_date, end_date)

    end

    private def census_by_project_type_source
      GrdaWarehouse::CensusByProjectType
    end

    private def census_by_project_source
      GrdaWarehouse::CensusByProject
    end

    def history_source
      GrdaWarehouse::ServiceHistoryEnrollment
    end

    def history_scope
      history_source.service.where.not(history_source.project_type_column => nil)
    end


  end
end
