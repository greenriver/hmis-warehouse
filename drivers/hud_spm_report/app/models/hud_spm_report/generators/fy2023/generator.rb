###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudSpmReport::Generators::Fy2023
  class Generator < ::HudReports::GeneratorBase
    cattr_accessor :write_detail_path

    def self.fiscal_year
      'FY 2023'
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
        HudSpmReport::Generators::Fy2023::MeasureOne,
        HudSpmReport::Generators::Fy2023::MeasureTwo,
        HudSpmReport::Generators::Fy2023::MeasureThree,
        HudSpmReport::Generators::Fy2023::MeasureFour,
        HudSpmReport::Generators::Fy2023::MeasureFive,
        HudSpmReport::Generators::Fy2023::MeasureSix,
        HudSpmReport::Generators::Fy2023::MeasureSeven,
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

    def self.client_class(question)
      questions[question].client_class
    end

    def self.pii_columns
      ['enrollment.first_name', 'first_name', 'enrollment.last_name', 'last_name', 'dob', 'ssn']
    end

    def self.detail_template
      'hud_spm_report/cells/show'
    end

    def self.uploadable_version?
      true
    end
  end
end
