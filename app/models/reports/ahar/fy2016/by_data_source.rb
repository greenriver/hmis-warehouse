###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Reports::Ahar::Fy2016
  class ByDataSource < Base
    def self.report_name
      'AHAR By Data Source - FY 2016'
    end

    def report_type
      0
    end

    def has_custom_form?
      true
    end

    def has_options?
      true
    end

    def has_data_source_option?
      true
    end

    def has_date_range_options?
      true
    end

    def title_for_options
      'Data Source'
    end

    def value_for_options options
      ds_id = options['data_source'].to_i
      GrdaWarehouse::DataSource.order(:short_name).find(ds_id.to_i).short_name
    end
  end
end
