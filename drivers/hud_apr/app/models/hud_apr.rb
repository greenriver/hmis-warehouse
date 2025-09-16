###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr
  def self.current_generator(report:)
    version = ::HudReports::BaseController.new.default_report_version
    case report
    when :caper
      "HudApr::Generators::Caper::#{version.to_s.capitalize}::Generator".constantize
    when :apr
      "HudApr::Generators::Apr::#{version.to_s.capitalize}::Generator".constantize
    when :ce_apr
      "HudApr::Generators::CeApr::#{version.to_s.capitalize}::Generator".constantize
    else
      raise
    end
  end
end
