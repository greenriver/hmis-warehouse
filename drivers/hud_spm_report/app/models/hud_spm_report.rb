###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudSpmReport
  def self.current_generator
    active_version = ::HudReports::BaseController.new.default_report_version
    case active_version
    when :fy2026
      HudSpmReport::Generators::Fy2026::Generator
    else
      raise "Generator not configured for version \"#{active_version}\""
    end
  end
end
