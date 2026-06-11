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
      active_version = ::HudReports::BaseController.new.default_report_version
      enrollment_class_name = "HudSpmReport::#{active_version.to_s.camelize}::SpmEnrollment"
      has_many :spm_enrollments, class_name: enrollment_class_name
    end
  end
end
