###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudSpmReport::Generators::Fy2024
  class Generator < ::HudReports::GeneratorBase
    def self.fiscal_year
      'FY 2024'
    end

    def self.generic_title
      'System Performance Measures'
    end

    def self.short_name
      'SPM'.freeze
    end

    def self.default_project_type_codes
      HudUtility2024.residential_project_type_numbers_by_code.keys
    end

    def url
      hud_reports_spm_url(report, { host: ENV['FQDN'], protocol: 'https' })
    end

    def self.questions
      [
        HudSpmReport::Generators::Fy2024::MeasureOne,
        HudSpmReport::Generators::Fy2024::MeasureTwo,
        HudSpmReport::Generators::Fy2024::MeasureThree,
        HudSpmReport::Generators::Fy2024::MeasureFour,
        HudSpmReport::Generators::Fy2024::MeasureFive,
        HudSpmReport::Generators::Fy2024::MeasureSix,
        HudSpmReport::Generators::Fy2024::MeasureSeven,
      ].map do |q|
        [q.question_number, q]
      end.to_h.freeze
    end

    def self.filter_class
      ::Filters::HudFilterBase
    end

    def self.valid_question_number(question_number)
      questions.keys.detect { |q| q == question_number } || questions.keys.first
    end

    def self.client_class(_question)
      # FIXME
      HudSpmReport::Fy2024::SpmEnrollment
    end
  end
end
