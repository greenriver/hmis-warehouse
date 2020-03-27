###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::HealthEmergency
  class Test < GrdaWarehouseBase
    include ::HealthEmergency

    def title
      'Testing Results'
    end

    def pill_title
      'Test'
    end

    def result_options
      [
        'Positive',
        'Negative',
      ]
    end

    def status
      return 'Unknown' if tested_on.blank?
      return 'Positive' if result == 'Positive'
      return 'Negative' if result == 'Negative'
      return 'Tested' if tested_on.present?

      'Unknown'
    end
  end
end