###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::HealthEmergency
  class Quarantine < IsolationBase

    def status
      return 'In Quarantine' if started_on && ended_on.blank?
      return "In Quarantine until #{ended_on}" if started_on

      'Unknown'
    end
  end
end
