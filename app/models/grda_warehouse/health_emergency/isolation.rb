###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::HealthEmergency
  class Isolation < IsolationBase

    def status
      return 'In Isolation' if started_on && ended_on.blank?
      return "In Isolation until #{started_on}" if started_on

      'Unknown'
    end
  end
end
