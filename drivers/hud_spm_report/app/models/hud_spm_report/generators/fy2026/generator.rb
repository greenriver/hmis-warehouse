###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudSpmReport::Generators::Fy2026
  class Generator < ::HudReports::GeneratorBase
    cattr_accessor :write_detail_path

    def self.fiscal_year
      'FY 2026'
    end

    def self.generic_title
      'System Performance Measures'
    end

    def self.short_name
      'SPM'
    end

    def self.supports_idempotent_retry?
      true
    end

    def self.default_project_type_codes
      HudHelper.util('2026').residential_project_type_numbers_by_code.keys
    end

    def url
      hud_reports_spm_url(report, { host: ENV['FQDN'], protocol: 'https' })
    end

    def prepare_report
      super

      HudReports::HouseholdContextBuilder.call(
        self,
        report,
        enrollment_scope: spm_enrollment_scope,
        lookback_years: 7,
      )
    end

    def self.questions
      [
        HudSpmReport::Generators::Fy2026::MeasureOne,
        HudSpmReport::Generators::Fy2026::MeasureTwo,
        HudSpmReport::Generators::Fy2026::MeasureThree,
        HudSpmReport::Generators::Fy2026::MeasureFour,
        HudSpmReport::Generators::Fy2026::MeasureFive,
        HudSpmReport::Generators::Fy2026::MeasureSix,
        HudSpmReport::Generators::Fy2026::MeasureSeven,
        HudSpmReport::Generators::Fy2026::HdxUpload,
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

    def self.client_scope(question)
      questions[question].client_scope
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

    def self.archival_csv_config(report_instance)
      enrollment_ids = HudSpmReport::Fy2026::SpmEnrollment.where(report_instance_id: report_instance.id).select(:id)
      episode_ids = HudReports::UniverseMember.where(
        report_cell_id: report_instance.report_cells.select(:id),
        universe_membership_type: 'HudSpmReport::Fy2026::Episode',
      ).pluck(:universe_membership_id)

      HudReportArchival.shared_archival_entries(report_instance, prefix: 'spm').merge(
        spm_bed_nights_csv: {
          scope: -> { HudSpmReport::Fy2026::BedNight.where(enrollment_id: enrollment_ids) },
          filename: -> { "hud-spm-fy2026-#{report_instance.id}-spm-bed-nights.csv" },
          delete_order: 2,
        },
        spm_enrollment_links_csv: {
          scope: -> { HudSpmReport::Fy2026::EnrollmentLink.where(enrollment_id: enrollment_ids) },
          filename: -> { "hud-spm-fy2026-#{report_instance.id}-spm-enrollment-links.csv" },
          delete_order: 3,
        },
        spm_returns_csv: {
          scope: -> { HudSpmReport::Fy2026::Return.where(report_instance_id: report_instance.id) },
          filename: -> { "hud-spm-fy2026-#{report_instance.id}-spm-returns.csv" },
          delete_order: 4,
        },
        spm_episodes_csv: {
          scope: -> { HudSpmReport::Fy2026::Episode.where(id: episode_ids) },
          filename: -> { "hud-spm-fy2026-#{report_instance.id}-spm-episodes.csv" },
          delete_order: 5,
        },
        spm_enrollments_csv: {
          scope: -> { HudSpmReport::Fy2026::SpmEnrollment.where(report_instance_id: report_instance.id) },
          filename: -> { "hud-spm-fy2026-#{report_instance.id}-spm-enrollments.csv" },
          delete_order: 6,
        },
      )
    end

    # HudReportArchival.register_archival_generator(self.title, self) runs when this
    # concern is included. Include at the end of the class to ensure all required fields
    # are loaded for registration
    include HudSpmReport::Archival

    private

    def spm_enrollment_scope
      HudSpmReport::Fy2026::SpmEnrollment.she_scope(report)
    end
  end
end
