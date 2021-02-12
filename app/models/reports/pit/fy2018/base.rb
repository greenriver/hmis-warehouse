###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Reports::Pit::Fy2018
  class Base < Report
    def self.report_name
      'PIT - FY 2018'
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

    def options?
      true
    end

    def custom_form?
      true
    end

    def pit_options?
      true
    end

    def coc_codes_option?
      true
    end

    def title_for_options
      'Dates'
    end

    def value_for_options options
      value = "PIT: #{options['pit_date']}, Chronic: #{options['chronic_date']}" if options.present?
      value += ", CoC Code(s): #{options['coc_codes'].join(' ')}" if options['coc_codes'].present? && options['coc_codes'].select(&:present?).any?
      value
    end
  end
end
