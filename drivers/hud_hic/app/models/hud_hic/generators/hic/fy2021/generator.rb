###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module  HudHic::Generators::Hic::Fy2021
  class Generator < ::HudReports::GeneratorBase
    def self.fiscal_year
      'FY 2021'
    end

    def self.generic_title
      'Housing Inventory Count'
    end

    def self.short_name
      'HIC'
    end

    def url
      hud_reports_hic_url(report, { host: ENV['FQDN'], protocol: 'https' })
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
        HudHic::Generators::Hic::Fy2021::Organization,
        HudHic::Generators::Hic::Fy2021::Project,
        HudHic::Generators::Hic::Fy2021::ProjectCoc,
        HudHic::Generators::Hic::Fy2021::Inventory,
        HudHic::Generators::Hic::Fy2021::Funder,
      ].map do |q|
        [q.question_number, q]
      end.to_h.freeze
    end

    def self.valid_question_number(question_number)
      questions.keys.detect { |q| q == question_number } || 'Project'
    end

    def self.table_classes
      [
        HudHic::Fy2021::Organization,
        HudHic::Fy2021::Project,
        HudHic::Fy2021::ProjectCoc,
        HudHic::Fy2021::Inventory,
        HudHic::Fy2021::Funder,
      ].freeze
    end
  end
end
