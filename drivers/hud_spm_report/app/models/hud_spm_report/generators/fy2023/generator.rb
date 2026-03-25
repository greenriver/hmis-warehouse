###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudSpmReport::Generators::Fy2023
  class Generator < ::HudReports::GeneratorBase
    def self.fiscal_year = 'FY 2023'
    def self.generic_title = 'System Performance Measures'
    def self.short_name = 'SPM'
    def self.filter_class = ::Filters::HudFilterBase

    def self.default_project_type_codes
      HudHelper.util('2024').residential_project_type_numbers_by_code.keys
    end

    def self.uploadable_version? = true

    def self.pii_columns
      ['enrollment.first_name', 'first_name', 'enrollment.last_name', 'last_name', 'dob', 'ssn']
    end

    def self.detail_template = 'hud_spm_report/cells/show'

    def url
      hud_reports_spm_url(report, { host: ENV['FQDN'], protocol: 'https' })
    end

    # Frozen snapshot of question metadata for historical report viewing/drilldowns.
    LegacyQuestion = Data.define(:question_number, :_client_class, :_scope_proc) do
      def client_class = _client_class

      def client_scope = _scope_proc ? _scope_proc.call : _client_class.preload(enrollment: :project)
    end

    def self.questions
      @questions ||= [
        LegacyQuestion.new(
          question_number: 'Measure 1',
          _client_class: HudSpmReport::Fy2023::Episode,
          _scope_proc: -> { HudSpmReport::Fy2023::Episode.joins(:enrollments).preload(enrollments: { enrollment: :project }) },
        ),
        LegacyQuestion.new(
          question_number: 'Measure 2',
          _client_class: HudSpmReport::Fy2023::Return,
          _scope_proc: -> {
            HudSpmReport::Fy2023::Return.
              left_outer_joins(:exit_enrollment, :return_enrollment).
              preload(:exit_enrollment, :return_enrollment)
          },
        ),
        LegacyQuestion.new(question_number: 'Measure 3', _client_class: HudSpmReport::Fy2023::SpmEnrollment, _scope_proc: nil),
        LegacyQuestion.new(question_number: 'Measure 4', _client_class: HudSpmReport::Fy2023::SpmEnrollment, _scope_proc: nil),
        LegacyQuestion.new(question_number: 'Measure 5', _client_class: HudSpmReport::Fy2023::SpmEnrollment, _scope_proc: nil),
        LegacyQuestion.new(question_number: 'Measure 6', _client_class: HudSpmReport::Fy2023::SpmEnrollment, _scope_proc: nil),
        LegacyQuestion.new(question_number: 'Measure 7', _client_class: HudSpmReport::Fy2023::SpmEnrollment, _scope_proc: nil),
        LegacyQuestion.new(question_number: 'HDX Upload', _client_class: HudSpmReport::Fy2023::SpmEnrollment, _scope_proc: nil),
      ].index_by(&:question_number).freeze
    end

    def self.valid_question_number(num) = questions.keys.detect { |q| q == num } || questions.keys.first
    def self.client_class(question) = questions[question].client_class
    def self.client_scope(question) = questions[question].client_scope
  end
end
