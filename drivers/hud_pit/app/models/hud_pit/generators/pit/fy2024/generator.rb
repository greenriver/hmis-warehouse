###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module  HudPit::Generators::Pit::Fy2024
  class Generator < ::HudReports::GeneratorBase
    def self.fiscal_year
      'FY 2024'
    end

    def self.generic_title
      'Point in Time Count'
    end

    def self.short_name
      'PIT'
    end

    def self.allowed_options
      [
        :on,
        :coc_codes,
        :project_ids,
        :data_source_ids,
        :project_type_codes,
        :project_group_ids,
      ]
    end

    def self.default_project_type_codes
      HudUtility2024.homeless_project_type_codes
    end

    def url
      hud_reports_pit_url(report, { host: ENV['FQDN'], protocol: 'https' })
    end

    def client_scope(on_date: filter.on)
      scope = client_source.
        distinct.
        joins(:service_history_enrollments).
        merge(report_scope_source.hud_residential.ongoing(on_date: on_date))

      @filter = self.class.filter_class.new(
        user_id: @report.user_id,
        enforce_one_year_range: false,
      ).update(@report.options)

      # Make sure we take advantage of the additive nature of HUD report filters
      @filter.project_ids = @report.project_ids

      scope = scope.merge(@filter.apply(GrdaWarehouse::ServiceHistoryEnrollment.all))

      scope.select(:id)
    end
    memoize :client_scope

    def filter
      @filter = self.class.filter_class.new(
        user_id: @report.user_id,
        enforce_one_year_range: false,
      ).update(@report.options)

      # Make sure we take advantage of the additive nature of HUD report filters
      @filter.project_ids = @report.project_ids
      @filter
    end

    def self.filter_class
      ::Filters::HudFilterBase
    end

    def self.questions
      [].map do |q|
        [q.question_number, q]
      end.to_h.freeze
    end

    def self.valid_table_name(table)
      valid_question_number(table)
    end

    def self.valid_question_number(question_number)
      questions.keys.detect { |q| q == question_number } || 'Projects'
    end

    def self.table_classes
      [
        HudPit::Fy2022::PitClient,
      ].freeze
    end

    def self.client_class(_question)
      HudPit::Fy2022::PitClient
    end
  end
end