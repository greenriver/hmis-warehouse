###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Reports::Lsa::Fy2018
  class Base < Report
    def self.report_name
      'LSA - FY 2018'
    end

    def report_group_name
      'Longitudinal System Analysis '
    end

    def file_name options
      "#{name}-#{options['coc_code']}"
    end

    def download_type
      :zip
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
      # Project types are integral to LSA business logic; only ES, SH, TH, RRH, and PSH projects should be available to select as parameters.
      GrdaWarehouse::Hud::Project.coc_funded.with_hud_project_type([1, 2, 3, 8, 13])
    end

    def self.available_data_sources
      GrdaWarehouse::DataSource.importable
    end

    def self.available_sub_populations
      AvailableSubPopulations.available_sub_populations
      # [
      #   ['All Clients', :all_clients],
      #   ['Veteran', :veteran],
      #   ['Youth', :youth],
      #   ['Parents', :family_parents],
      #   ['Parenting Youth', :parenting_youth],
      #   ['Parenting Children', :parenting_children],
      #   ['Individual Adults', :individual_adults],
      #   ['Non Veteran', :non_veteran],
      #   ['Family', :family],
      #   ['Youth Families', :youth_families],
      #   ['Children', :children],
      #   ['Unaccompanied Minors', :unaccompanied_minors],
      # ]
    end

    def value_for_options options
      return '' unless options.present?
      display_string = "Report Start: #{options['report_start']}; Report End: #{options['report_end']}"
      display_string << "; CoC-Code: #{options['coc_code']}" if options['coc_code'].present?
      display_string << "; Data Source: #{GrdaWarehouse::DataSource.short_name(options['data_source_id'].to_i)}" if options['data_source_id'].present?
      display_string << project_id_string(options)
      display_string << project_group_string(options)
      display_string << sub_population_string(options)
      display_string
    end

    protected

    def project_id_string options
      str = ''
      if options['project_id'].present?
        if options['project_id'].is_a?(Array)
          if options['project_id'].delete_if(&:blank?).any?
            str = "; Projects: #{options['project_id'].map{|m| GrdaWarehouse::Hud::Project.find_by_id(m.to_i)&.name || m if m.present?}.compact.join(', ')}"
          end
        else
          str = "; Project: #{GrdaWarehouse::Hud::Project.find_by_id(options['project_id'].to_i)&.name || options['project_id'] }"
        end
      end
      return str
    end

    def project_group_string options
      if (pg_ids = options['project_group_ids']&.compact) && pg_ids&.any?
        names = GrdaWarehouse::ProjectGroup.where(id: pg_ids).pluck(:name)
        if names.any?
          return "; Project Groups: #{names.join(', ')}"
        end
      end
      ''
    end

    def sub_population_string options
      if (sub_population = options['sub_population']) && sub_population.present?
        return "; Sub Population: #{sub_population.humanize.titleize}"
      end
      ''
    end


  end
end
