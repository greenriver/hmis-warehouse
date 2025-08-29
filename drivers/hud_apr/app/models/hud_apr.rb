###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr
  TodoOrDie('Set APR Default Generator on Staging to FY 2026 version', by: '2025-09-01')
  TodoOrDie('Set APR Default Generator to the FY 2026 version', by: '2025-10-01')
  def self.current_generator(report:)
    case report
    when :caper
      HudApr::Generators::Caper::Fy2024::Generator
    when :apr
      HudApr::Generators::Apr::Fy2024::Generator
    when :ce_apr
      HudApr::Generators::CeApr::Fy2024::Generator
    else
      raise
    end
  end
end
