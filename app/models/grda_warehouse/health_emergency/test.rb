###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::HealthEmergency
  class Test < GrdaWarehouseBase
    include ::HealthEmergency

    scope :visible_to, -> (user) do
      return current_scope if user.can_see_health_emergency_clinical?

      none
    end

    scope :tested_within_range, -> (range=Date.current..Date.current) do
      where(tested_on: range)
    end

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