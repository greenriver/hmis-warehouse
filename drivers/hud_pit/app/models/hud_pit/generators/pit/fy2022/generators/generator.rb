###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module  HudPit::Generators::Pit::Fy2022
  class Generator < ::HudReports::GeneratorBase
    def self.fiscal_year
      'FY 2022'
    end

    def self.generic_title
      'Point in Time Count'
    end

    def self.short_name
      'PIT'
    end

    def url
      hud_reports_pit_url(report, { host: ENV['FQDN'], protocol: 'https' })
    end

    def filter
      @filter = self.class.filter_class.new(
        user_id: @report.user_id,
        enforce_one_year_range: false,
      ).update(@report.options)

      # Make sure we take advantage of the additive nature of HUD report filters
      @filter.project_ids = @report.project_ids
      @filter
    end

    def project_scope
      GrdaWarehouse::Hud::Project.where(id: filter.project_ids).
        active_on(filter.on).
        joins(:project_cocs).
        merge(GrdaWarehouse::Hud::ProjectCoc.in_coc(coc_code: filter.coc_codes))
    end

    def project_coc_scope
      GrdaWarehouse::Hud::ProjectCoc.joins(:project).
        merge(project_scope)
    end

    def organization_scope
      GrdaWarehouse::Hud::Organization.joins(:projects).
        merge(project_scope).distinct
    end

    def funder_scope
      GrdaWarehouse::Hud::Funder.joins(:project).
        merge(project_scope)
    end

    def inventory_scope
      GrdaWarehouse::Hud::Inventory.active_on(filter.on).
        in_coc(coc_code: filter.coc_codes).
        joins(:project).
        merge(project_scope)
    end

    def self.filter_class
      ::Filters::HudFilterBase
    end

    def self.questions
      [
        HudPit::Generators::Pit::Fy2022::Organization,
      ].map do |q|
        [q.question_number, q]
      end.to_h.freeze
    end

    def self.valid_question_number(question_number)
      questions.keys.detect { |q| q == question_number } || 'Project'
    end

    def self.table_classes
      [
        HudPit::Fy2022::Organization,
      ].freeze
    end
  end
end
