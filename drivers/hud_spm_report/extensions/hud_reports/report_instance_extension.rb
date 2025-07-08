###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudSpmReport::HudReports
  module ReportInstanceExtension
    extend ActiveSupport::Concern

    included do
      TodoOrDie("Set SPM Default Generator to 'HudSpmReport::Fy2026::SpmEnrollment'", by: '2025-10-01')
      active_version = ::HudReports::BaseController.new.default_report_version
      enrollment_class_name = if active_version == :fy2026
        'HudSpmReport::Fy2026::SpmEnrollment'
      else
        'HudSpmReport::Fy2024::SpmEnrollment'
      end
      has_many :spm_enrollments, class_name: enrollment_class_name
    end
  end
end
