###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::HealthEmergency
  class Test < GrdaWarehouseBase
    include ::HealthEmergency

    def visible_to?(user)
      user.can_see_health_emergency_clinical?
    end

    def title
      'Testing Results'
    end

    def pill_title
      'Test'
    end

    def result_options
      {
        'Positive' => 'Positive',
        'Negative' => 'Negative',
      }
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