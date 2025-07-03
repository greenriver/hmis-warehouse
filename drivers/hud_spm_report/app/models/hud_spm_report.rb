###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudSpmReport
  def self.current_generator
    TodoOrDie("Set SPM Default Generator on Staging to 'HudSpmReport::Generators::Fy2026::Generator'", by: '2025-09-01')
    TodoOrDie("Set SPM Default Generator to 'HudSpmReport::Generators::Fy2026::Generator'", by: '2025-10-01')
    return HudSpmReport::Generators::Fy2024::Generator if Rails.env.production? && Date.current <= '2025-10-01'.to_date
    return HudSpmReport::Generators::Fy2024::Generator if Rails.env.staging? && Date.current <= '2025-09-01'.to_date

    HudSpmReport::Generators::Fy2026::Generator
  end
end
