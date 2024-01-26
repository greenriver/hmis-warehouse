###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudSpmReport::Generators::Fy2020
  class Generator < ::HudReports::GeneratorBase
    def self.fiscal_year
      'FY 2020'
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
        HudSpmReport::Generators::Fy2020::MeasureOne,
        HudSpmReport::Generators::Fy2020::MeasureTwo,
        HudSpmReport::Generators::Fy2020::MeasureThree,
        HudSpmReport::Generators::Fy2020::MeasureFour,
        HudSpmReport::Generators::Fy2020::MeasureFive,
        HudSpmReport::Generators::Fy2020::MeasureSix,
        HudSpmReport::Generators::Fy2020::MeasureSeven,
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
      HudApr::Fy2020::SpmClient
    end

    def self.question_fields(question)
      q_num = question[/\d+\z/]
      column_names.select { |c| c.starts_with? "m#{q_num}" }.map(&:to_sym)
    end

    def self.common_fields
      [
        :client_id,
        :source_client_personal_ids,
        :first_name,
        :last_name,
      ]
    end

    def self.uploadable_version?
      false
    end
  end
end
