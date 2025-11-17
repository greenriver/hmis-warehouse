###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# @see docs/features/hud_spm_report.md
module HudSpmReport::Generators::Fy2026
  class Generator < ::HudReports::GeneratorBase
    cattr_accessor :write_detail_path

    def prepare_report
      start_time = Time.current
      Rails.logger.info "SPM FY2026: Starting report preparation for Report ##{report.id}"

      super

      # Pre-create enrollment set to track timing separately
      enrollment_start = Time.current
      Rails.logger.info 'SPM FY2026: Creating enrollment set...'
      HudSpmReport::Fy2026::SpmEnrollment.create_enrollment_set(report)
      enrollment_duration = Time.current - enrollment_start
      Rails.logger.info "SPM FY2026: Enrollment set creation completed in #{enrollment_duration.round(2)}s (#{report.spm_enrollments.count} enrollments)"

      total_duration = Time.current - start_time
      Rails.logger.info "SPM FY2026: Report preparation completed in #{total_duration.round(2)}s"
    end

    def self.fiscal_year
      'FY 2026'
    end

    def self.generic_title
      'System Performance Measures'
    end

    def self.short_name
      'SPM'
    end

    def self.default_project_type_codes
      HudHelper.util('2026').residential_project_type_numbers_by_code.keys
    end

    def url
      hud_reports_spm_url(report, { host: ENV['FQDN'], protocol: 'https' })
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
  end
end
