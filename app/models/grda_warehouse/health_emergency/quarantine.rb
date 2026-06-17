###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::HealthEmergency
  class Quarantine < IsolationBase

    def title
      'Quarantine'
    end

    def status
      return "Since #{started_on}" if started_on

      'Unknown'
    end
  end
end
