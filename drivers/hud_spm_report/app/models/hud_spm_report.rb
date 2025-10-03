###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudSpmReport
  def self.current_generator
    active_version = ::HudReports::BaseController.new.default_report_version
    if active_version == :fy2026
      HudSpmReport::Generators::Fy2026::Generator
    else
      HudSpmReport::Generators::Fy2024::Generator
    end
  end
end
