###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudSpmReport::Generators::Fy2024
  class Generator < ::HudReports::GeneratorBase
    def self.fiscal_year = 'FY 2024'
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

      def table_descriptions = {}
    end

    def self.questions
      @questions ||= [
        LegacyQuestion.new(
          question_number: 'Measure 1',
          _client_class: HudSpmReport::Fy2024::Episode,
          _scope_proc: -> { HudSpmReport::Fy2024::Episode.joins(:enrollments).preload(enrollments: { enrollment: :project }) },
        ),
        LegacyQuestion.new(
          question_number: 'Measure 2',
          _client_class: HudSpmReport::Fy2024::Return,
          _scope_proc: -> {
            HudSpmReport::Fy2024::Return.
              left_outer_joins(:exit_enrollment, :return_enrollment).
              preload(:exit_enrollment, :return_enrollment)
          },
        ),
        LegacyQuestion.new(question_number: 'Measure 3', _client_class: HudSpmReport::Fy2024::SpmEnrollment, _scope_proc: nil),
        LegacyQuestion.new(question_number: 'Measure 4', _client_class: HudSpmReport::Fy2024::SpmEnrollment, _scope_proc: nil),
        LegacyQuestion.new(question_number: 'Measure 5', _client_class: HudSpmReport::Fy2024::SpmEnrollment, _scope_proc: nil),
        LegacyQuestion.new(question_number: 'Measure 6', _client_class: HudSpmReport::Fy2024::SpmEnrollment, _scope_proc: nil),
        LegacyQuestion.new(question_number: 'Measure 7', _client_class: HudSpmReport::Fy2024::SpmEnrollment, _scope_proc: nil),
        LegacyQuestion.new(question_number: 'HDX Upload', _client_class: HudSpmReport::Fy2024::SpmEnrollment, _scope_proc: nil),
      ].index_by(&:question_number).freeze
    end

    def self.valid_question_number(num) = questions.keys.detect { |q| q == num } || questions.keys.first
    def self.client_class(question) = questions[question].client_class
    def self.client_scope(question) = questions[question].client_scope

    def self.archival_csv_config(report_instance)
      enrollment_ids = HudSpmReport::Fy2024::SpmEnrollment.where(report_instance_id: report_instance.id).select(:id)
      episode_ids = HudReports::UniverseMember.where(
        report_cell_id: report_instance.report_cells.select(:id),
        universe_membership_type: 'HudSpmReport::Fy2024::Episode',
      ).pluck(:universe_membership_id)

      HudReportArchival.shared_archival_entries(report_instance, prefix: 'spm').merge(
        spm_enrollment_links_csv: {
          scope: -> { HudSpmReport::Fy2024::EnrollmentLink.where(enrollment_id: enrollment_ids) },
          filename: -> { "hud-spm-fy2024-#{report_instance.id}-spm-enrollment-links.csv" },
          delete_order: 2,
        },
        spm_returns_csv: {
          scope: -> { HudSpmReport::Fy2024::Return.where(report_instance_id: report_instance.id) },
          filename: -> { "hud-spm-fy2024-#{report_instance.id}-spm-returns.csv" },
          delete_order: 3,
        },
        spm_episodes_csv: {
          scope: -> { HudSpmReport::Fy2024::Episode.where(id: episode_ids) },
          filename: -> { "hud-spm-fy2024-#{report_instance.id}-spm-episodes.csv" },
          delete_order: 4,
        },
        spm_enrollments_csv: {
          scope: -> { HudSpmReport::Fy2024::SpmEnrollment.where(report_instance_id: report_instance.id) },
          filename: -> { "hud-spm-fy2024-#{report_instance.id}-spm-enrollments.csv" },
          delete_order: 5,
        },
      )
    end

    # HudReportArchival.register_archival_generator(self.title, self) runs when this
    # concern is included. Include at the end of the class to ensure all required fields
    # are loaded for registration
    include HudSpmReport::Archival
  end
end
