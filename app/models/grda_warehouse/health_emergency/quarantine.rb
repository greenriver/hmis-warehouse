###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::HealthEmergency
  class Quarantine < IsolationBase

    def title
      'Quarantine'
    end

    def status
      return "In Quarantine until #{started_on}" if started_on

      'Unknown'
    end
  end
end
