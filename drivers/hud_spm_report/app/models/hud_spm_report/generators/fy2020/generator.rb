###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudSpmReport::Generators::Fy2020
  class Generator < ::HudReports::GeneratorBase
    def self.fiscal_year = 'FY 2020'
    def self.generic_title = 'System Performance Measures'
    def self.short_name = 'SPM'
    def self.filter_class = ::Filters::HudFilterBase

    def self.default_project_type_codes
      HudHelper.util('2024').residential_project_type_numbers_by_code.keys
    end

    def self.uploadable_version? = false

    def self.pii_columns
      ['first_name', 'last_name', 'dob', 'ssn']
    end

    def url
      hud_reports_spm_url(report, { host: ENV['FQDN'], protocol: 'https' })
    end

    def self.questions
      @questions ||= [
        'Measure 1',
        'Measure 2',
        'Measure 3',
        'Measure 4',
        'Measure 5',
        'Measure 6',
        'Measure 7',
      ].map { |q| [q, Data.define(:question_number).new(question_number: q)] }.to_h.freeze
    end

    def self.valid_question_number(n) = questions.keys.detect { |q| q == n } || questions.keys.first

    def self.client_class(_question)
      HudApr::Fy2020::SpmClient
    end

    def self.client_scope(question)
      client_class(question)
    end

    def self.question_fields(question)
      q_num = question[/\d+\z/]
      HudApr::Fy2020::SpmClient.column_names.select { |c| c.starts_with? "m#{q_num}" }.map(&:to_sym)
    end

    def self.common_fields
      [
        :client_id,
        :source_client_personal_ids,
        :first_name,
        :last_name,
      ]
    end
  end
end
