###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::HealthEmergency
  class Isolation < IsolationBase

    def title
      'Isolation'
    end

    def status
      return "Since #{started_on}" if started_on

      'Unknown'
    end
  end
end
