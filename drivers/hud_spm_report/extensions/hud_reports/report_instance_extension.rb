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
      if Rails.env.production? && Date.current < '2025-10-01'.to_date
        has_many :spm_enrollments, class_name: 'HudSpmReport::Fy2024::SpmEnrollment'
      elsif Rails.env.staging? && Date.current < '2025-09-01'.to_date
        has_many :spm_enrollments, class_name: 'HudSpmReport::Fy2024::SpmEnrollment'
      else
        has_many :spm_enrollments, class_name: 'HudSpmReport::Fy2026::SpmEnrollment'
      end
    end
  end
end
