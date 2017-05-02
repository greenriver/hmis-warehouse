module Reports::SystemPerformance::Fy2016
  class Base < Report
    def self.report_name
      'HUD System Performance Reports - FY 2016'
    end

    def download_type
      :csv
    end

    def has_options?
      true
    end

    def has_custom_form?
      true
    end

    def title_for_options
      'Limits'
    end

    def self.available_projects
      GrdaWarehouse::Hud::Project.all
    end

    def self.available_data_sources
      GrdaWarehouse::DataSource.all
    end

    def value_for_options options
      return '' unless options.present?
      display_string = "Report Start: #{options['report_start']}; Report End: #{options['report_end']}"
      display_string << "; CoC-Code: #{options['coc_code']}" if options['coc_code'].present?
      display_string << "; Data Source: #{GrdaWarehouse::DataSource.short_name(options['data_source_id'].to_i)}" if options['data_source_id'].present?
      display_string << "; Project: #{GrdaWarehouse::Hud::Project.find(options['project_id'].to_i).name}" if options['project_id'].present?
      display_string
    end

  end
end