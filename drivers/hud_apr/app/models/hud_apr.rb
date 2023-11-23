###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr
  def self.current_generator(report:)
    case report
    when :caper
      HudApr::Generators::Apr::Fy2024::Generator
    when :apr
      HudApr::Generators::Caper::Fy2024::Generator
    else
      raise
    end
  end
end
