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
      has_many :spm_enrollments, class_name: 'HudSpmReport::Fy2026::SpmEnrollment'
    end
  end
end
