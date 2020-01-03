###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Reports::Ahar::Fy2017
  class ByDataSource < Base
    def self.report_name
      'AHAR By Data Source - FY 2017'
    end

    def self.generator
      ReportGenerators::Ahar::Fy2017::ByDataSource
    end

    def self.available_options
      super + [:data_source]
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