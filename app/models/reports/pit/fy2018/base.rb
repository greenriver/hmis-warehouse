###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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

    def has_options? # rubocop:disable Naming/PredicateName
      true
    end

    def has_custom_form? # rubocop:disable Naming/PredicateName
      true
    end

    def has_pit_options? # rubocop:disable Naming/PredicateName
      true
    end

    def has_coc_codes_option? # rubocop:disable Naming/PredicateName
      true
    end

    def title_for_options
      'Dates'
    end

    def describe_filter_as_html(_)
      ''
    end

    def allowed_options(result)
      options_from_result(result).keys.map(&:to_sym)
    end

    def filter_from_result(result)
      # Old PITs don't the filter, but the HudFilterBase will handle display.
      f = ::Filters::HudFilterBase.new(user_id: result.user_id)
      f.update(options_from_result(result).with_indifferent_access)
      f
    end

    private def options_from_result(result)
      options = result.options.deep_dup
      # Cleanup some discrepancies
      options[:on] = options.delete('pit_date')
      options[:start] = nil
      options[:end] = nil
      options
    end

    def value_for_options options
      value = "PIT: #{options['pit_date']}, Chronic: #{options['chronic_date']}" if options.present?
      value += ", CoC Code(s): #{options['coc_codes'].join(' ')}" if options['coc_codes'].present? && options['coc_codes'].select(&:present?).any?
      value += ", Project(s): #{project_names(options['project_ids']).join(' ')}" if options['project_ids'].present? && options['project_ids'].select(&:present?).any?
      value += ", Project Group(s): #{project_group_names(options['project_group_ids']).join(' ')}" if options['project_group_ids'].present? && options['project_group_ids'].select(&:present?).any?

      value
    end

    private def project_names(ids)
      GrdaWarehouse::Hud::Project.where(id: ids).map(&:organization_and_name)
    end

    private def project_group_names(ids)
      GrdaWarehouse::ProjectGroup.where(id: ids).map(&:name)
    end
  end
end
