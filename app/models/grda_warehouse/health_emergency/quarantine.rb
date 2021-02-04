###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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
