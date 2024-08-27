###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Filters
  class HopwaCaperFilter < ::Filters::HudFilterBase
    def funder_ids
      HudUtility2024.funder_components.fetch('HUD: HOPWA')
    end
  end
end
