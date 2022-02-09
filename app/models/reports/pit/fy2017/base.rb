###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Reports::Pit::Fy2017
  class Base < Report
    def self.report_name
      'PIT - FY 2017'
    end

    def report_group_name
      'Point in Time (PIT)'
    end

    def continuum_name
      @continuum_name ||= GrdaWarehouse::Config.get(:continuum_name)
    end

    def download_type
      nil
    end

    def has_options?
      true
    end

    def has_custom_form?
      true
    end

    def has_pit_options?
      true
    end

    def title_for_options
      'Dates'
    end

    def value_for_options options
      "PIT: #{options['pit_date']}, Chronic: #{options['chronic_date']}" if options.present?
    end
  end
end
