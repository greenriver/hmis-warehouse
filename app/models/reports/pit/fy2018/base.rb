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

    def has_options?
      true
    end

    def has_custom_form?
      true
    end

    def has_pit_options?
      true
    end

    def has_coc_codes_option?
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