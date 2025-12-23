###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ServiceScanning
  class ExtrapolatedOutreach < Service
    def title
      'Extrapolated Outreach Contact'
    end

    def slug
      :extrapolated_outreach
    end
  end
end
