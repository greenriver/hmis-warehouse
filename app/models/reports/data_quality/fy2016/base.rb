###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Reports::DataQuality::Fy2016
  class Base < Report
    def self.report_name
      'HUD Data Quality Reports - FY 2016'
    end

    def report_group_name
      'Data Quality'
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

    def self.available_project_types
      HUD::project_types.invert
    end

    def self.available_data_sources
      GrdaWarehouse::DataSource.importable
    end

    def value_for_options options
      return '' unless options.present?
      display_string = "Report Start: #{options['report_start']}; Report End: #{options['report_end']}"
      display_string << "; CoC-Code: #{options['coc_code']}" if options['coc_code'].present?
      display_string << "; Data Source: #{GrdaWarehouse::DataSource.short_name(options['data_source_id'].to_i)}" if options['data_source_id'].present?
      display_string << project_id_string(options)
      display_string << "; Project Types: #{options['project_type'].map{|m| HUD.project_type(m.to_i) if m.present?}.compact.join(', ')}" if options['project_type'].present? && options['project_type'].delete_if(&:blank?).any?
      display_string << project_group_string(options)
      display_string
    end

    protected

    def project_group_string options
      if (pg_ids = options['project_group_ids']&.compact) && pg_ids&.any?
        names = GrdaWarehouse::ProjectGroup.where(id: pg_ids).pluck(:name)
        return "; Project Groups: #{names.join(', ')}"
      end
      ''
    end

    def project_id_string options
      str = ''
      if options['project_id'].present?
        if options['project_id'].is_a?(Array)
          if options['project_id'].delete_if(&:blank?).any?
            str = "; Projects: #{options['project_id'].map{|m| GrdaWarehouse::Hud::Project.find(m.to_i).name if m.present?}.compact.join(', ')}"
          end
        else
          str = "; Project: #{GrdaWarehouse::Hud::Project.find(options['project_id'].to_i).name}"
        end
      end
      return str
    end
  end
end
