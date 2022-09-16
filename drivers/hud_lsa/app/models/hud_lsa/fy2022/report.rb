###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudLsa::Fy2022
  class Report < ::Report
    include ArelHelper
    def self.report_name
      'LSA - FY 2022'
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

    def has_options? # rubocop:disable Naming/PredicateName
      true
    end

    def has_custom_form? # rubocop:disable Naming/PredicateName
      true
    end

    def title_for_options
      'Limits'
    end

    def self.available_projects(user:)
      # Project types are integral to LSA business logic; only ES, SH, TH, PSH projects should be available to select as parameters.
      # Section 2.1 requires that the projects available to a user for selection when entering report parameters must be limited to ProjectTypes ES (1), SH (8), TH (2), RRH (13), and PSH (3), so records for other project types are never included when LSAScope = 2.
      # NOTE: app/models/report_generators/lsa/fy2022/base.rb will define a different set for system-wide LSAScope = 1

      project_scope = GrdaWarehouse::Hud::Project.coc_funded.with_hud_project_type([1, 2, 3, 8, 13])
      GrdaWarehouse::Hud::Project.options_for_select(user: user, scope: project_scope)
    end

    def self.available_data_sources
      GrdaWarehouse::DataSource.importable
    end

    def self.available_lsa_scopes
      {
        'System-Wide' => 1,
        'Project-focused' => 2,
      }
    end

    # # This is somewhat circular until the LSA is re-written to use the standard filter set
    # def allowed_options(result)
    #   options_from_result(result).keys.map(&:to_sym)
    # end

    # def filter_from_result(result)
    #   # LSA doesn't actually use a filter yet, but the HudFilterBase will handle things appropriately.
    #   f = ::Filters::HudFilterBase.new(user_id: result.user_id)
    #   f.update(options_from_result(result).with_indifferent_access)
    #   f
    # end

    # def describe_filter_as_html(result)
    #   f = filter_from_result(result)
    #   f.describe_filter_as_html(allowed_options(result))
    # end

    # private def options_from_result(result)
    #   options = result.options.deep_dup
    #   # Cleanup some discrepancies
    #   options[:project_ids] = options.delete('project_id')
    #   options[:start] = options.delete('report_start')
    #   options[:end] = options.delete('report_end')
    #   options
    # end

    # def value_for_options options
    #   return '' unless options.present?

    #   display_string = "Report Start: #{options['report_start']}; Report End: #{options['report_end']}"
    #   display_string << "; CoC-Code: #{options['coc_code']}" if options['coc_code'].present?
    #   display_string << "; Scope: #{self.class.available_lsa_scopes.invert[options['lsa_scope']&.to_i] || 'Auto Select'}"
    #   display_string << "; Data Source: #{GrdaWarehouse::DataSource.short_name(options['data_source_id'].to_i)}" if options['data_source_id'].present?
    #   display_string << "; Data Sources: #{GrdaWarehouse::DataSource.where(id: options['data_source_ids'].select(&:present?).map(&:to_i)).pluck(:short_name).to_sentence}" if options['data_source_ids'].present?
    #   display_string << project_id_string(options)
    #   display_string << project_group_string(options)
    #   display_string << sub_population_string(options)
    #   display_string
    # end

    # private def project_id_string options
    #   str = ''
    #   if options['project_id'].present?
    #     if options['project_id'].is_a?(Array)
    #       if options['project_id'].delete_if(&:blank?).any?
    #         str = "; Projects: #{options['project_id'].map do |m|
    #           GrdaWarehouse::Hud::Project.find_by_id(m.to_i)&.name || m if m.present?
    #         end.compact.join(', ')}"
    #       end
    #     else
    #       str = "; Project: #{GrdaWarehouse::Hud::Project.find_by_id(options['project_id'].to_i)&.name || options['project_id']}"
    #     end
    #   end
    #   str
    # end

    # private def project_group_string options
    #   pg_ids = options['project_group_ids']&.compact
    #   if pg_ids && pg_ids&.any?
    #     names = GrdaWarehouse::ProjectGroup.where(id: pg_ids).pluck(:name)
    #     return "; Project Groups: #{names.join(', ')}" if names.any?
    #   end

    #   ''
    # end

    # private def sub_population_string options
    #   sub_population = options['sub_population']
    #   return "; Sub Population: #{sub_population.humanize.titleize}" if sub_population && sub_population.present?

    #   ''
    # end
  end
end
