###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Reports::SystemPerformance::Fy2019
  class Base < Report
    def self.report_name
      'HUD System Performance Reports - FY 2019'
    end

    def report_group_name
      'System Performance Measures'
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

    def has_race_options?
      true
    end

    def title_for_options
      'Limits'
    end

    def self.available_projects
      GrdaWarehouse::Hud::Project.all
    end

    def self.available_data_sources
      GrdaWarehouse::DataSource.importable
    end

    def self.available_races
      {
        AmIndAKNative: :race_am_ind_ak_native,
        Asian: :race_asian,
        BlackAfAmerican: :race_black_af_american,
        NativeHIOtherPacific: :race_native_hi_other_pacific,
        White: :race_white,
        RaceNone: :race_none,
      }
    end

    def self.available_ethnicities

    end

    def self.available_sub_populations
      AvailableSubPopulations.available_sub_populations.merge(
        {
          'Youth' => :youth,
          'Parents' => :family_parents,
          'Parenting Youth' => :parenting_youth,
          'Parenting Children' => :parenting_children,
          'Youth Families' => :youth_families,
          'Unaccompanied Minors' => :unaccompanied_minors,
        }
      )
    end

    def value_for_options options
      return '' unless options.present?
      display_string = "Report Start: #{options['report_start']}; Report End: #{options['report_end']}"
      display_string << "; CoC-Code: #{options['coc_code']}" if options['coc_code'].present?
      display_string << "; Data Source: #{GrdaWarehouse::DataSource.short_name(options['data_source_id'].to_i)}" if options['data_source_id'].present?
      display_string << "; Data Source: #{options['data_source_ids'].map { |id| GrdaWarehouse::DataSource.short_name(id.to_i) }.join(', ')}" if options['data_source_ids'].present?
      display_string << project_id_string(options)
      display_string << project_group_string(options)
      display_string << sub_population_string(options)
      display_string << race(options)
      display_string << ethnicity(options)
      display_string
    end

    protected

    def project_id_string options
      str = ''
      if options['project_id'].present?
        if options['project_id'].is_a?(Array)
          if options['project_id'].delete_if(&:blank?).any?
            str = "; Projects: #{options['project_id'].map { |m| GrdaWarehouse::Hud::Project.find(m.to_i).name if m.present? rescue m }.compact.join(', ')}"
          end
        else
          str = "; Project: #{GrdaWarehouse::Hud::Project.find(options['project_id'].to_i).name}"
        end
      end
      return str
    end

    def project_group_string options
      if (pg_ids = options['project_group_ids']&.compact) && pg_ids&.any?
        names = GrdaWarehouse::ProjectGroup.where(id: pg_ids).pluck(:name)
        return "; Project Groups: #{names.join(', ')}"
      end
      ''
    end

    def sub_population_string options
      if (sub_population = options['sub_population']) && sub_population.present?
        return "; Sub Population: #{sub_population.humanize.titleize}"
      end
      ''
    end

    def race options
      if options['race_code'].present?
        race = self.class.available_races.invert[options['race_code']&.to_sym]
        return "; Race: #{race}"
      else
        ''
      end
    end

    def ethnicity options
      if options['ethnicity_code'].present?
        ethnicity = HUD.ethnicity(options['ethnicity_code'].to_i)
        return "; Ethnicity: #{ethnicity}"
      else
        ''
      end
    end


  end
end
